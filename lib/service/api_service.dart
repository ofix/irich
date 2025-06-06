// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/api_service.dart
// Purpose:     api request service
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

// ignore_for_file: avoid_print
import 'dart:collection';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:irich/service/api_providers/api_provider.dart';
import 'package:irich/service/api_provider_capabilities.dart';
import 'package:irich/service/load_balancer.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/service/request_log.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/utils/rich_result.dart';

enum RetryPolicy {
  none, // 不重试
  linear, // 线性重试
  exponential, // 指数退避重试
}

class ApiConfig {
  final int maxRetries;
  final RetryPolicy retryPolicy;
  final bool abortOnCriticalError;
  final Duration timeoutPerRequest;

  static const Duration defaultTimeout = Duration(seconds: 3000);

  const ApiConfig({
    this.maxRetries = 2,
    this.retryPolicy = RetryPolicy.linear,
    this.abortOnCriticalError = true,
    this.timeoutPerRequest = defaultTimeout,
  });

  Duration getRetryDelay(int attempt) {
    return switch (retryPolicy) {
      RetryPolicy.linear => Duration(seconds: attempt * 2),
      RetryPolicy.exponential => Duration(seconds: pow(2, attempt).toInt()),
      RetryPolicy.none => Duration.zero,
    };
  }
}

class ApiService {
  final LoadBalancer _balancer; // 负载均衡
  final _stats = _RequestStats(); // 请求状态管理
  final _requestQueue = _PriorityRequestQueue(); // 请求队列（重试请求优先）
  final _stopwatch = Stopwatch();
  final ApiConfig _apiConfig;
  final int _maxConn; // 最大并发数
  final _activeRequests = <_ActiveRequest>[];
  final ProviderApiType _curApiType; // 当前API请求类别
  bool _isCanceled = false; // 取消异步并发请求
  bool _isPaused = false; // 暂停异步并发请求

  /// [apiType] 请求类别
  /// [maxConn] 最大请求并发数
  ApiService(ProviderApiType apiType, [int maxConn = 2, ApiConfig apiConfig = const ApiConfig()])
    : _maxConn = maxConn.clamp(1, 4),
      _curApiType = apiType,
      _apiConfig = apiConfig,
      _balancer = LoadBalancer(apiType);

  double get speed => _stats.realTimeSpeed; // 请求速度
  double get progress => _stats.progress; // 请求进度

  /// [providers] 指定供应商列表，覆盖默认的供应商列表，
  /// 相当于剔除无法使用的供应商
  void providers(List<EnumApiProvider> providers) {
    _balancer.replaceDefaultProviders(providers);
  }

  void cancel() {
    _isCanceled = true; // 取消并发请求
    _requestQueue.clear(); // 清空待处理队列
    for (var r in _activeRequests) {
      r.completer.completeError(Exception("Canceled"));
    }
  }

  void pause() {
    _isPaused = true; // 暂停并发请求
    _requestQueue.clear(); // 清空待处理队列
    for (var r in _activeRequests) {
      r.completer.completeError(Exception("Paused"));
    }
  }

  /// 请求耗时
  int get elapsedSeconds => _stopwatch.elapsed.inSeconds;

  /// 重置统计状态
  void _resetState() {
    _isCanceled = false;
    _stats.reset();
    _stopwatch.reset();
  }

  /// [shareCode] 当前请求的股票编码
  /// [extraParams] 不同类型的单个请求，除了shareCode，参数可能不一样
  Future<(RichResult, dynamic)> fetch(String shareCode, [Map<String, dynamic>? extraParams]) async {
    Map<String, dynamic> params = {};
    if (shareCode != "") {
      final Share? share = StoreQuote.query(shareCode);
      if (share == null) {
        return (error(RichStatus.shareNotExist), null);
      }
      params = {"ShareCode": share.code, "Market": share.market, "ShareName": share.name};
      if (extraParams != null) {
        params.addAll(extraParams.cast<String, Object>());
      }
    }
    final response = await _balancer.request(params);
    return (success(), response);
  }

  /// 异步并发请求
  /// [params] 异步并发请求的参数集合
  /// [onProgress] 爬取过程中的回调函数
  Future<(RichResult, List<Map<String, dynamic>>)> batchFetch(
    List<Map<String, dynamic>> params, [
    void Function(RequestLog requestLog)? onProgress,
    void Function(RequestLog requestLog)? onPagerProgress, // 分页进度
  ]) async {
    _resetState();
    _requestQueue.addAll(params);
    _stopwatch.start();

    final responses = <Map<String, dynamic>>[];

    while ((!_requestQueue.isEmpty || _activeRequests.isNotEmpty)) {
      // 填充活跃请求
      while (_activeRequests.length < _maxConn && !_requestQueue.isEmpty) {
        final request = _requestQueue.nextRequest();
        final completer = Completer<_RequestResult>();
        final activeRequest = _ActiveRequest(request, completer);
        _processRequest(
          request,
          responses,
          onPagerProgress,
        ).then((result) => completer.complete(result));
        _activeRequests.add(activeRequest);
      }

      // 等待任意请求完成
      final completed = await Future.any(_activeRequests.map((r) => r.completer.future));

      // 移除完成的请求
      _activeRequests.removeWhere((r) => r.completer.isCompleted);

      // 处理结果
      if (completed.isSuccess) {
        onProgress?.call(completed.requestLog);
      } else if (completed.isRetryable) {
        _requestQueue.scheduleRetry(completed.params, _apiConfig.maxRetries);
      }

      // 错误熔断检查
      if (_shouldAbort(completed.error)) {
        break;
      }
    }
    _stopwatch.stop();
    if (_isCanceled) {
      return (error(RichStatus.taskCancelled), responses); // 任务被取消
    }
    if (_isPaused) {
      return (error(RichStatus.taskCancelled), responses); // 任务被暂停
    }
    return (success(), responses);
  }

  // 改进的请求处理方法（支持优先级标记）
  Future<_RequestResult> _processRequest(
    Map<String, dynamic> params,
    List<dynamic> responses, [
    void Function(RequestLog requestLog)? onPagerProgress, // 分页进度
  ]) async {
    DateTime requestTime = DateTime.now();
    DateTime responseTime = requestTime;
    dynamic oneResult;
    late RequestLog requestLog;
    try {
      oneResult = await _balancer
          .httpRequest(params, onPagerProgress)
          .timeout(_apiConfig.timeoutPerRequest);
      DateTime responseTime = DateTime.now();
      if (oneResult is List<ApiResult>) {
        int size = 0;
        for (int i = 0; i < oneResult.length; i++) {
          size += oneResult[i].responseBytes;
        }
        _stats.recordSuccess(size);
        final data = _balancer.apiProvider.parseResponse(_curApiType, oneResult); // 解析当前返回数据
        final result = <String, dynamic>{};
        result["Params"] = params;
        result["Response"] = data;
        responses.add(result);
        requestLog = RequestLog(
          taskId: params['TaskId'],
          providerId: _balancer.apiProvider.provider,
          apiType: _curApiType,
          responseBytes: size,
          requestTime: requestTime,
          responseTime: responseTime,
          url: "",
          statusCode: 200,
          duration: responseTime.difference(requestTime).inMilliseconds,
        );
        return _RequestResult.success(params, requestLog);
      } else if (oneResult is ApiResult) {
        _stats.recordSuccess(oneResult.response.length);
        requestLog = RequestLog(
          taskId: params['TaskId'],
          providerId: _balancer.apiProvider.provider,
          apiType: _curApiType,
          responseBytes: oneResult.response.length,
          requestTime: requestTime,
          responseTime: responseTime,
          url: oneResult.url,
          statusCode: oneResult.statusCode,
          duration: responseTime.difference(requestTime).inMilliseconds,
        );
        final data = _balancer.apiProvider.parseResponse(
          _curApiType,
          oneResult.response,
        ); // 解析当前返回数据
        final result = <String, dynamic>{};
        result["Params"] = params;
        result["Response"] = data;
        responses.add(result);
        return _RequestResult.success(params, requestLog);
      }
      requestLog = RequestLog(
        taskId: "",
        providerId: _balancer.apiProvider.provider,
        apiType: _curApiType,
        responseBytes: 0,
        requestTime: requestTime,
        responseTime: responseTime,
        url: "",
        statusCode: 500,
        duration: responseTime.difference(requestTime).inMilliseconds,
      );
      return _RequestResult.failure(params, requestLog, "internal error");
    } catch (e) {
      if (!_isCanceled) {
        _stats.recordFailure();
        if (e is TimeoutException) _stats.recordTimeout();
      }
      requestLog = RequestLog(
        taskId: params['TaskId'],
        providerId: _balancer.apiProvider.provider,
        apiType: _curApiType,
        responseBytes: (oneResult['Response'] as String).length,
        requestTime: requestTime,
        responseTime: responseTime,
        url: oneResult['Url'],
        statusCode: oneResult['StatucCode'],
        duration: responseTime.difference(requestTime).inMilliseconds,
      );
      return _RequestResult.failure(params, requestLog, e);
    }
  }

  bool _shouldAbort(dynamic error) {
    return error is SocketException || error is TimeoutException;
  }
}

class _ActiveRequest {
  final Map<String, dynamic> params;
  final Completer<_RequestResult> completer;

  _ActiveRequest(this.params, this.completer);
}

/// 请求统计
class _RequestStats {
  int _successCount = 0;
  int _failureCount = 0;
  int _timeoutCount = 0;
  double _bytesReceived = 0;
  DateTime? _startTime;

  double get realTimeSpeed {
    final elapsed = _startTime != null ? DateTime.now().difference(_startTime!).inSeconds : 1;
    return elapsed > 0 ? _bytesReceived / elapsed : 0;
  }

  double get progress {
    final total = _successCount + _failureCount + _timeoutCount;
    return total > 0 ? _successCount / total : 0;
  }

  void recordSuccess(int bytes) {
    _successCount++;
    _bytesReceived += bytes;
  }

  void recordTimeout() => _timeoutCount++;
  void recordFailure() => _failureCount++;
  void reset() {
    _successCount = 0;
    _failureCount = 0;
    _bytesReceived = 0;
    _timeoutCount = 0;
    _startTime = null;
  }
}

// 优先级请求队列
class _PriorityRequestQueue {
  final _requestQueue = Queue<Map<String, dynamic>>();
  final _retryQueue = Queue<Map<String, dynamic>>();
  final _retryCounts = <Map<String, dynamic>, int>{};

  bool get isEmpty => _retryQueue.isEmpty && _requestQueue.isEmpty;

  void addAll(Iterable<Map<String, dynamic>> requests) {
    _requestQueue.addAll(requests);
    // 需要初始化重试计数
    for (final request in requests) {
      _retryCounts.putIfAbsent(request, () => 0);
    }
  }

  void scheduleRetry(Map<String, dynamic> request, int maxRetries) {
    final count = _retryCounts[request] ?? 0;
    if (count < maxRetries) {
      _retryCounts[request] = count + 1;
      _retryQueue.addLast(request);
    }
  }

  void clear() {
    _requestQueue.clear();
    _retryQueue.clear();
    _retryCounts.clear();
  }

  Map<String, dynamic> nextRequest() {
    // 优先返回重试队列请求
    return _retryQueue.isNotEmpty ? _retryQueue.removeFirst() : _requestQueue.removeFirst();
  }
}

// 增强的请求结果
class _RequestResult {
  final Map<String, dynamic> params;
  final RequestLog requestLog;
  final dynamic error;

  bool get isSuccess => error == null;
  bool get isRetryable => error is! SocketException && error is! TimeoutException;
  _RequestResult.success(this.params, this.requestLog) : error = null;
  _RequestResult.failure(this.params, this.requestLog, this.error);
}
