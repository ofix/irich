import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:irich/service/request_log.dart';
import 'package:irich/service/sql_service.dart';

class RequestLogger {
  late SqlService sqlService;
  final List<RequestLog> _errorLogs = [];
  Timer? _flushTimer;
  final int _maxBufferSize = 10;
  final Duration _flushInterval = const Duration(seconds: 30);

  RequestLogger() {
    sqlService = SqlService.instance;
    _startFlushTimer();
  }
  // 启动定时刷新定时器
  void _startFlushTimer() {
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flushBuffer());
  }

  // 日志超过5条后，批量插入数据库
  Future<void> _flushBuffer() async {
    if (_errorLogs.isEmpty) return;

    final logsToInsert = List<RequestLog>.from(_errorLogs);
    _errorLogs.clear();

    try {
      final logs = <Map<String, dynamic>>[];
      for (final log in logsToInsert) {
        logs.add(log.toMap());
      }
      sqlService.batchInsert('request_log', logs);
      if (kDebugMode) {
        print('成功批量写入 ${logsToInsert.length} 条日志');
      }
    } catch (e) {
      // 如果写入失败，将日志重新放回缓冲区
      _errorLogs.addAll(logsToInsert);
      if (kDebugMode) {
        print('日志批量写入失败: $e');
      }
    }
  }

  // 记录爬虫请求错误日志
  Future<void> logError({
    required String providerId,
    required String apiType,
    required String url,
    required int? statusCode,
    required String errorMessage,
    required int duration,
  }) async {
    final log = RequestLog(
      providerId: providerId,
      apiType: apiType,
      url: url,
      requestTime: DateTime.now(),
      statusCode: statusCode,
      errorMessage: errorMessage,
      duration: duration,
    );

    // 输出到控制台
    debugPrint('''
[Crawler Error]
Provider: $providerId
API Type: $apiType
URL: $url
Status: ${statusCode ?? 'N/A'}
Error: $errorMessage
Duration: ${duration}ms
''');

    // 添加到缓冲区
    _errorLogs.add(log);

    // 检查是否需要立即刷新
    if (_errorLogs.length >= _maxBufferSize) {
      await _flushBuffer();
      _flushTimer?.cancel();
      _startFlushTimer();
    }
  }

  /// 获取未处理的错误日志
  Future<List<RequestLog>> getUnresolvedLogs() async {
    // 首先刷新缓冲区，确保所有日志都已写入
    await _flushBuffer();

    final maps = await sqlService.query(
      'request_log',
      where: 'is_resolved = ?',
      whereArgs: [0],
      orderBy: 'request_time DESC',
    );

    // 合并内存中的未写入日志（虽然_flushBuffer已经清空，但这里保持接口一致性）
    final allLogs = [
      ...maps.map((map) => RequestLog.fromMap(map)),
      ..._errorLogs.where((log) => !log.isResolved),
    ];

    // 按时间降序排序
    allLogs.sort((a, b) => b.requestTime.compareTo(a.requestTime));

    return allLogs;
  }

  /// 销毁日志类
  Future<void> dispose() async {
    await _flushBuffer();
    _flushTimer?.cancel();
  }

  // 标记错误已解决
  Future<void> markAsResolved(int id) async {
    // 先检查内存中的日志
    final memoryLog = _errorLogs.firstWhere(
      (log) => log.id == id,
      orElse:
          () => RequestLog(
            providerId: '',
            apiType: '',
            url: '',
            requestTime: DateTime.now(),
            duration: 0,
            id: -1, // 无效ID
          ),
    );

    if (memoryLog.id != -1) {
      memoryLog.isResolved = true;
      return;
    }

    // 如果不在内存中，更新数据库
    await sqlService.update('request_log', {'is_resolved': 1}, where: 'id = ?', whereArgs: [id]);
  }

  /// 增加重试次数
  /// [id] 错误日志ID
  Future<void> incrementRetryCount(int id) async {
    // 先检查内存中的日志
    final memoryLogIndex = _errorLogs.indexWhere((log) => log.id == id);
    if (memoryLogIndex != -1) {
      _errorLogs[memoryLogIndex].retryCount++;
      return;
    }

    // 如果不在内存中，更新数据库
    await sqlService.rawUpdate(
      'UPDATE request_log SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }
}
