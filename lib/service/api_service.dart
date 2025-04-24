// ignore_for_file: avoid_print
import 'dart:collection';
import 'dart:async';

import 'package:irich/service/api_provider_capabilities.dart';
import 'package:irich/service/load_balancer.dart';
import 'package:irich/types/stock.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/utils/rich_result.dart';

class ApiService {
  final LoadBalancer _balancer = LoadBalancer(); // 负载均衡器
  final _maxConnPerHost = 8; // 最大连接数
  // final _connTimeout = Duration(seconds: 15); // 连接超时

  // int _successRequests = 0; // 成功请求数
  // int _failedRequests = 0; // 失败请求数
  // int _requestCount = 0; // 请求总数
  // double _recvBytesCur = 0; // 当前接收字节数
  // double _recvBytesLast = 0; // 上次接收字节数
  // double _realTimeSpeed = 0; // 请求实时速度
  // List<double> _speedList = []; // 请求速度列表

  ApiService();

  // 抓取所有数据
  Future<void> fetchAll(EnumApiType enumApiType) async {
    // 根据请求的负载情况动态调整最大连接数
    final queue = Queue.from(StoreQuote.shares);
    final activeRequests = <Future>[];

    while (queue.isNotEmpty || activeRequests.isNotEmpty) {
      // 填充活跃请求队列至最大并发数
      while (activeRequests.length < _maxConnPerHost && queue.isNotEmpty) {
        final Share share = queue.removeFirst();
        final future = _balancer.request(enumApiType, {
          "shareCode": share.code,
          "market": share.market,
          "shareName": share.name,
        });
        activeRequests.remove(future);
        activeRequests.add(future);
      }
      // 等待任意一个请求完成
      await Future.any(activeRequests);
    }
  }

  Future<(RichResult, dynamic)> fetch(
    EnumApiType enumApiType,
    String shareCode, [
    Map<String, dynamic>? extraParams,
  ]) async {
    final Share share = StoreQuote.query(shareCode)!;
    final params = {
      "shareCode": share.code,
      "market": share.market,
      "shareName": share.name,
    };
    if (extraParams != null) {
      params.addAll(extraParams.cast<String, Object>());
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
