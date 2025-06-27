// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/tasks/task_mock.dart
// Purpose:     mock task scheduler tasks for testing
// Author:      songhuabiao
// Created:     2025-06-27 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';
import 'dart:math';
import 'package:irich/service/api_provider_capabilities.dart';
import 'package:irich/service/request_log.dart';
import 'package:irich/service/tasks/batch_api_task.dart';
import 'package:irich/service/tasks/task.dart';
import 'package:irich/service/task_events.dart';

class TaskMock extends BatchApiTask {
  @override
  TaskType type = TaskType.mock;
  @override
  ProviderApiType apiType = ProviderApiType.industry;
  TaskMock({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  TaskMock.build(super.json)
    : type = TaskType.fromVal(json['Type'] as int),
      apiType = ProviderApiType.fromVal(json['ApiType'] as int),
      super.build();

  ///
  @override
  Future<void> doJob() async {
    responses = [];
    List<Map<String, dynamic>> safeParams = params.cast<Map<String, dynamic>>();
    for (final item in safeParams) {
      item['TaskId'] = taskId;
    }
    originTotalRequests = 100;
    // 模拟任务执行
    for (int i = 0; i < 100; i++) {
      // 模拟单个请求（随机延时100-500ms）
      final requestTime = DateTime.now();
      await Future.delayed(Duration(milliseconds: 1000 + Random().nextInt(400)));
      final responseTime = DateTime.now();
      final log = RequestLog(
        taskId: params['TaskId'],
        providerId: EnumApiProvider.eastMoney,
        apiType: apiType,
        responseBytes: Random().nextInt(60000), // 模拟响应字节数
        requestTime: requestTime,
        responseTime: responseTime,
        url: "https://mockapi.com/api/industry?page=$i",
        statusCode: 200,
        duration: responseTime.difference(requestTime).inMilliseconds,
      );
      doneRequests += 1;
      progress = doneRequests / originTotalRequests; // 计算进度
      final progressEvent = TaskProgressEvent(
        threadId: threadId,
        taskId: taskId,
        progress: progress,
        requestLog: log,
      );
      notifyUi(progressEvent);
    }
  }

  @override
  Future<void> run() async {
    await doJob();
  }

  @override
  Future<dynamic> onCompletedUi(TaskCompletedEvent event, dynamic result) async {}
}
