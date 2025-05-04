// ignore_for_file: avoid_print
import 'dart:collection';
import 'dart:async';
import 'dart:io';
import 'dart:nativewrappers/_internal/vm/lib/math_patch.dart';

import 'package:irich/service/api_provider_capabilities.dart';
import 'package:irich/service/load_balancer.dart';
import 'package:irich/types/stock.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/utils/rich_result.dart';
import 'package:path_provider/path_provider.dart';

enum RetryPolicy {
  none, // 不重试
  linear, // 线性重试
  exponential, // 指数退避重试
}

class ApiConfig {
  final int maxRetries;
  final RetryPolicy retryPolicy;
  final bool abortOnCriticalError;
  final Duration? timeoutPerRequest;

  const ApiConfig({
    this.maxRetries = 3,
    this.retryPolicy = RetryPolicy.linear,
    this.abortOnCriticalError = true,
    this.timeoutPerRequest,
  });
}

class ApiService {
  late LoadBalancer _balancer; // 负载均衡器
  late ProviderApiType _apiType; // 当前的请求主题

  int _maxConnPerHost = 8; // 最大连接数
  // final _connTimeout = Duration(seconds: 15); // 连接超时
  bool _concurrentCanceled = false;

  // 请求统计
  int _successRequests = 0; // 成功请求数
  int _failedRequests = 0; // 失败请求数
  int _requestCount = 0; // 请求总数
  double _recvBytesCur = 0; // 当前接收字节数
  double _realTimeSpeed = 0; // 请求实时速度

  DateTime? _startTime;

  ApiService(ProviderApiType apiType) : _apiType = apiType, _balancer = LoadBalancer(apiType);

  // 获取当前请求速度
  double get speed => _realTimeSpeed;
  // 获取当前请求进度
  double get progress =>
      _requestCount == 0 ? 0 : (_successRequests + _failedRequests) / _requestCount;

  // 取消并发请求
  void cancel() {
    _concurrentCanceled = true;
  }

  // 辅助方法：更新实时速度
  void _updateSpeed() {
    if (_startTime == null) return;
    final elapsedTime = DateTime.now().difference(_startTime!).inSeconds;
    if (elapsedTime > 0) {
      _realTimeSpeed = _recvBytesCur / elapsedTime;
    }
  }

  // 辅助方法：检查Future是否完成（同步方式）
  bool _isComplete(Future future) {
    var isComplete = false;
    future.then((_) => isComplete = true, onError: (_) => isComplete = true);
    return isComplete;
  }

  // 辅助方法：并发请求完成后保存数据到本地文件
  Future<RichResult> saveToFile(String filePath, String content) async {
    try {
      final file = File(filePath);
      await file.create(recursive: true); // 确保目录存在
      await file.writeAsString(content);
      return success();
    } catch (e) {
      return error(RichStatus.fileWriteFailed, desc: e.toString());
    }
  }

  // 辅助方法：序列化数据为CSV格式
  String _serializeToJson(dynamic data) {
    return data.entries.map((e) => '"${e.key}":"${e.value}"').join(',');
  }

  // 序列化为CSV格式
  String _serializeToCsv(dynamic data) {
    return data.values.join(',');
  }

  // 获取文件路径和序列化方法
  Future<({String path, String Function(Map<String, dynamic>) serializer})> _getPathAndSerializer(
    ProviderApiType apiType,
  ) async {
    final basePath = (await getApplicationDocumentsDirectory()).path;
    return switch (apiType) {
      ProviderApiType.dayKline => (path: '$basePath/dayKline.json', serializer: _serializeToJson),
      ProviderApiType.industry => (path: '$basePath/industry.csv', serializer: _serializeToCsv),
      ProviderApiType.concept => (path: '$basePath/concept.csv', serializer: _serializeToCsv),
      ProviderApiType.province => (path: '$basePath/province.csv', serializer: _serializeToCsv),
      _ => throw ArgumentError('Unsupported API type'),
    };
  }

  // 重置计数器
  void _resetCounters() {
    _concurrentCanceled = false;
    _successRequests = 0;
    _failedRequests = 0;
    _requestCount = 0;
    _recvBytesCur = 0;
    _realTimeSpeed = 0;
  }

  // 异步并发请求
  Future<(RichResult, List<dynamic>)> concurrentFetch(
    List<Map<String, dynamic>> urls, [
    void Function(Map<String, dynamic>)? onProgress,
    ApiConfig config = const ApiConfig(),
  ]) async {
    final queue = Queue.from(urls);
    _requestCount = queue.length;
    _resetCounters();
    final activeParams = <Map<String, dynamic>>[];
    final activeRequests = <Future>[];
    final responses = <dynamic>[];
    _startTime = DateTime.now();

    //容错机制
    bool shouldAbort = false; // 新增：是否中止后续请求的标志
    final retryQueue = Queue<Map<String, dynamic>>();
    final retryCounts = <Map<String, dynamic>, int>{};

    while ((queue.isNotEmpty || activeRequests.isNotEmpty) && !shouldAbort) {
      if (_concurrentCanceled) {
        // 请求当前请求
        break;
      }
      // 填充活跃请求队列至最大并发数
      while (activeRequests.length < _maxConnPerHost && queue.isNotEmpty) {
        // 优先处理重试队列
        if (retryQueue.isNotEmpty && activeRequests.length < _maxConnPerHost) {
          final params = retryQueue.removeFirst();
          queue.addFirst(params);
        }

        final params = queue.removeFirst();
        final future = _processRequestWithRetry(
          params,
          responses,
          config,
          retryQueue,
          retryCounts,
        ).catchError((error, stackTrace) {
          if (_shouldAbortOnError(error)) {
            shouldAbort = true;
          }
          return null;
        });

        activeRequests.add(future);
        activeParams.add(params);
      }
      // 等待至少一个请求完成
      if (activeRequests.isNotEmpty) {
        await Future.any(activeRequests);
        for (int i = 0; i < activeRequests.length; i++) {
          final request = activeRequests[i];
          if (_isComplete(request)) {
            // 移除已完成的请求
            activeRequests.removeAt(i);
            final finishedRequestParams = activeParams.removeAt(i);
            // 完成请求进度通知
            onProgress?.call(finishedRequestParams);
          }
        }

        activeRequests.removeWhere((f) => _isComplete(f));
      }
    }
    // 等待所有剩余请求完成
    return (success(), responses);
  }

  // 增加请求重试机制
  Future<void> _processRequestWithRetry(
    Map<String, dynamic> params,
    List<dynamic> responses,
    ApiConfig config,
    Queue<Map<String, dynamic>> retryQueue,
    Map<Map<String, dynamic>, int> retryCounts,
  ) async {
    int attempt = 0;
    dynamic lastError;

    do {
      attempt++;
      try {
        final response = await _processRequest(
          params,
          responses,
        ).timeout(config.timeoutPerRequest ?? Duration(seconds: 30));
        return response;
      } catch (error) {
        lastError = error;
        if (attempt <= config.maxRetries && _isRetryable(error)) {
          final delay = _calculateRetryDelay(attempt, config.retryPolicy);
          await Future.delayed(delay);
          retryCounts[params] = (retryCounts[params] ?? 0) + 1;
          retryQueue.addLast(params);
        } else {
          responses.add((params, lastError));
          throw lastError; // 重试次数用尽或不可重试错误
        }
      }
    } while (attempt <= config.maxRetries);

    throw lastError; // 永远不会执行到这里
  }

  bool _isRetryable(dynamic e) {
    return true;
  }

  // 辅助方法：根据错误类型判断是否中止
  bool _shouldAbortOnError(dynamic error) {
    // 可根据实际需求定制逻辑
    return error is SocketException || error is TimeoutException;
  }

  Duration _calculateRetryDelay(int attempt, RetryPolicy policy) {
    switch (policy) {
      case RetryPolicy.linear:
        return Duration(seconds: attempt * 2);
      case RetryPolicy.exponential:
        return Duration(seconds: pow(2, attempt).toInt());
      default:
        return Duration.zero;
    }
  }

  // 完成处理
  Future<RichResult> _onComplete(ProviderApiType ProviderApiType, List<dynamic> responses) async {
    try {
      final result = await _getPathAndSerializer(ProviderApiType);
      final path = result.path;
      final serializer = result.serializer;
      final content = responses.map((r) => serializer(r as Map<String, dynamic>)).join('\n');
      return await saveToFile(path, content);
    } catch (e) {
      return error(RichStatus.fileWriteFailed, desc: e.toString());
    }
  }

  // 处理单个请求
  Future<void> _processRequest(Map<String, dynamic> params, List<dynamic> responses) async {
    try {
      final response = await _balancer.request(params);
      _recvBytesCur += response.toString().length;
      _successRequests++;
      responses.add(response);
      _updateSpeed();
    } catch (e) {
      if (!_concurrentCanceled) {
        _failedRequests++;
        _updateSpeed();
      }
      rethrow;
    }
  }

  Future<(RichResult, dynamic)> fetch(String shareCode, [Map<String, dynamic>? extraParams]) async {
    Map<String, dynamic> params = {};
    if (shareCode != "") {
      final Share share = StoreQuote.query(shareCode)!;
      final params = {"shareCode": share.code, "market": share.market, "shareName": share.name};
      if (extraParams != null) {
        params.addAll(extraParams.cast<String, Object>());
      }
    }
    final response = await _balancer.request(params);
    return (success(), response);
  }

  // 并发控制执行
  // Future<dynamic> fetchAll(List<String> urls) async {
  //   return await Future.wait(
  //     urls.map((s) => _fetchWithRetry(s)),
  //     eagerError: true,
  //   );
  // }

  // 重试机制
  // Future<dynamic> _fetchWithRetry(String shareCode, {int retries = 3}) async {
  //   for (var i = 0; i < retries; i++) {
  //     try {
  //       return await _router.fetchDailyKline(shareCode);
  //     } catch (e) {
  //       if (i == retries - 1) rethrow;
  //       await Future.delayed(Duration(seconds: 1 << i));
  //     }
  //   }
  //   throw StateError('Unreachable');
  // }
}
