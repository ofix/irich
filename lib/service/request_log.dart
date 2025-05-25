// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/request_log.dart
// Purpose:     request log class for SQLite database
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/service/api_provider_capabilities.dart';

class RequestLog {
  int? id;
  final String taskId; // 任务ID
  final EnumApiProvider providerId; // 供应商ID
  final ProviderApiType apiType; // 请求类型
  final String url; // 请求URL
  final DateTime requestTime; // 请求时间
  final DateTime responseTime; // 响应时间
  final int duration; // 请求耗时，毫秒
  final int responseBytes; // 响应字节数
  final int? statusCode; // 响应状态吗
  final String? errorMessage; // 错误消息
  final double? pageProgress; // 分页进度

  int? retryCount; // 重试次数
  bool isResolved; // 任务是否已解决

  RequestLog({
    this.id,
    required this.taskId,
    required this.providerId,
    required this.apiType,
    required this.statusCode,
    required this.url,
    required this.requestTime,
    required this.responseTime,
    required this.duration,
    required this.responseBytes,
    this.errorMessage,
    this.retryCount = 0,
    this.isResolved = false,
    this.pageProgress = 0,
  });

  // 添加copyWith方法以便更新内存中的日志
  RequestLog copyWith({
    int? id, // 自增ID
    String? taskId, // 任务ID
    EnumApiProvider? providerId, // 供应商ID
    ProviderApiType? apiType, // API类别
    int? statusCode, // 状态吗
    String? url, // 请求URL
    DateTime? requestTime, // 请求时间
    DateTime? responseTime, // 响应时间
    int? duration, // 请求持续时间
    int? responseBytes, // 响应字节数
    String? errorMessage, // 错误信息
    int? retryCount, // 重试次数
    bool? isResolved, // 是否解决
    double? pageProgress, // 分页进度
  }) {
    return RequestLog(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      providerId: providerId ?? this.providerId,
      apiType: apiType ?? this.apiType,
      url: url ?? this.url,
      statusCode: statusCode ?? this.statusCode,
      requestTime: requestTime ?? this.requestTime,
      responseTime: responseTime ?? this.responseTime,
      duration: duration ?? this.duration,
      responseBytes: responseBytes ?? this.responseBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      isResolved: isResolved ?? this.isResolved,
      pageProgress: pageProgress ?? this.pageProgress,
    );
  }

  Map<String, dynamic> serialize() {
    return {
      'Id': id,
      'TaskId': taskId,
      'ProviderId': providerId.val,
      'ApiType': apiType.val,
      'StatusCode': statusCode,
      'Url': url,
      'RequestTime': requestTime.millisecondsSinceEpoch,
      'ResponseTime': responseTime.microsecondsSinceEpoch,
      'Duration': duration,
      'ResponseBytes': responseBytes,
      'ErrorMessage': errorMessage,
      'RetryCount': retryCount,
      'IsResolved': isResolved ? 1 : 0,
      'PageProgress': pageProgress,
    };
  }

  static List<Map<String, dynamic>> serializeList(List<RequestLog> logs) {
    return logs.map((log) => log.serialize()).toList();
  }

  factory RequestLog.deserialize(Map<String, dynamic> json) {
    return RequestLog(
      id: json['Id'],
      taskId: json['TaskId'],
      providerId: EnumApiProvider.fromVal(json['ProviderId'] as int),
      apiType: ProviderApiType.fromVal(json['ApiType'] as int),
      statusCode: json['StatusCode'],
      url: json['Url'],
      requestTime: DateTime.fromMillisecondsSinceEpoch(json['RequestTime']),
      responseTime: DateTime.fromMicrosecondsSinceEpoch(json['ResponseTime']),
      responseBytes: json['ResponseBytes'],
      errorMessage: json['ErrorMessage'],
      duration: json['Duration'],
      retryCount: json['RetryCount'],
      isResolved: json['IsResolved'] == 1,
      pageProgress: json['PageProgress'],
    );
  }
  static List<RequestLog> deserializeList(List<dynamic> jsonList) {
    return jsonList.map((json) => RequestLog.deserialize(json)).toList();
  }
}
