// ignore_for_file: avoid_print
import 'dart:collection';
import 'dart:async';
import 'dart:io';

import 'package:irich/service/api_provider_capabilities.dart';
import 'package:irich/service/load_balancer.dart';
import 'package:irich/types/stock.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/utils/rich_result.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  final LoadBalancer _balancer = LoadBalancer(); // 负载均衡器
  final _maxConnPerHost = 8; // 最大连接数
  // final _connTimeout = Duration(seconds: 15); // 连接超时
  bool _concurrentCanceled = false;

  // 请求统计
  int _successRequests = 0; // 成功请求数
  int _failedRequests = 0; // 失败请求数
  int _requestCount = 0; // 请求总数
  double _recvBytesCur = 0; // 当前接收字节数
  double _realTimeSpeed = 0; // 请求实时速度

  DateTime? _startTime;

  ApiService();

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
    EnumApiType enumApiType,
  ) async {
    final basePath = (await getApplicationDocumentsDirectory()).path;
    return switch (enumApiType) {
      EnumApiType.dayKline => (path: '$basePath/dayKline.json', serializer: _serializeToJson),
      EnumApiType.industry => (path: '$basePath/industry.csv', serializer: _serializeToCsv),
      EnumApiType.concept => (path: '$basePath/concept.csv', serializer: _serializeToCsv),
      EnumApiType.province => (path: '$basePath/province.csv', serializer: _serializeToCsv),
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
  Future<RichResult> concurrentFetch(
    EnumApiType enumApiType,
    List<Map<String, dynamic>> urls, [ // 请求的参数，不分GET/POST请求
    Future<RichResult> Function(EnumApiType, List<dynamic>)? onComplete, // 完成回调
  ]) async {
    final queue = Queue.from(urls);
    _requestCount = queue.length;
    _resetCounters();
    final activeRequests = <Future>[];
    final responses = <dynamic>[];
    _startTime = DateTime.now();

    while (queue.isNotEmpty || activeRequests.isNotEmpty) {
      if (_concurrentCanceled) {
        // 请求当前请求
        break;
      }
      // 填充活跃请求队列至最大并发数
      while (activeRequests.length < _maxConnPerHost && queue.isNotEmpty) {
        final params = queue.removeFirst();
        activeRequests.add(_processRequest(enumApiType, params, responses));
      }
      // 等待至少一个请求完成
      if (activeRequests.isNotEmpty) {
        await Future.any(activeRequests);
        // 移除已完成的请求
        activeRequests.removeWhere((f) => _isComplete(f));
      }
    }
    // 等待所有剩余请求完成
    return (onComplete ?? _onComplete).call(enumApiType, responses);
  }

  // 完成处理
  Future<RichResult> _onComplete(EnumApiType enumApiType, List<dynamic> responses) async {
    try {
      final result = await _getPathAndSerializer(enumApiType);
      final path = result.path;
      final serializer = result.serializer;
      final content = responses.map((r) => serializer(r as Map<String, dynamic>)).join('\n');
      return await saveToFile(path, content);
    } catch (e) {
      return error(RichStatus.fileWriteFailed, desc: e.toString());
    }
  }

  // 处理单个请求
  Future<void> _processRequest(
    EnumApiType enumApiType,
    Map<String, dynamic> params,
    List<dynamic> responses,
  ) async {
    try {
      final response = await _balancer.request(enumApiType, params);
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

  Future<(RichResult, dynamic)> fetch(
    EnumApiType enumApiType,
    String shareCode, [
    Map<String, dynamic>? extraParams,
  ]) async {
    Map<String, dynamic> params = {};
    if (shareCode != "") {
      final Share share = StoreQuote.query(shareCode)!;
      final params = {"shareCode": share.code, "market": share.market, "shareName": share.name};
      if (extraParams != null) {
        params.addAll(extraParams.cast<String, Object>());
      }
    }
    final response = await _balancer.request(enumApiType, params);
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
