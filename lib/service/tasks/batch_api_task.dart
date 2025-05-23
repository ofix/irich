// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/tasks/task_sync_share_region.dart
// Purpose:     synchronize share region task
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:convert';

import 'package:irich/global/config.dart';
import 'package:irich/service/api_provider_capabilities.dart';
import 'package:irich/service/api_service.dart';
import 'package:irich/service/request_log.dart';
import 'package:irich/service/tasks/task.dart';
import 'package:irich/service/task_events.dart';
import 'package:irich/utils/file_tool.dart';
import 'package:irich/utils/rich_result.dart';
import 'package:path/path.dart' as p;

abstract class BatchApiTask extends Task<void> {
  late ApiService apiService;
  ProviderApiType get apiType;
  int originTotalRequests; // 原始任务请求总数
  int totalRequests; // 任务请求总数
  int doneRequests; // 已完成任务请求数
  BatchApiTask({
    super.params,
    super.priority,
    super.submitTime,
    super.status,
    this.originTotalRequests = 0,
  }) : totalRequests = (params as List<Map<String, dynamic>>).length,
       doneRequests = 0 {
    if (originTotalRequests == 0) {
      originTotalRequests = totalRequests;
    }
  }

  /// 在子线程中运行
  Future<void> doJob() async {
    apiService = ApiService(apiType);
    final result = await apiService.batchFetch(
      params,
      (RequestLog log) {
        doneRequests += 1;
        progress = doneRequests / originTotalRequests; // 计算进度
        final progressEvent = TaskProgressEvent(
          threadId: threadId,
          taskId: taskId,
          progress: progress,
          requestLog: log,
        );
        notifyUi(progressEvent);
      },
      (RequestLog log) {
        progress = doneRequests / originTotalRequests; // 分页请求进度
        final progressEvent = TaskProgressEvent(
          threadId: threadId,
          taskId: taskId,
          progress: progress,
          requestLog: log,
        );
        notifyUi(progressEvent);
      },
    );

    final (status, response) = result;
    if (status.status == RichStatus.taskPaused) {
      // 任务真的暂停成功
      await _savePausedTask(params, response);
      final pausedEvent = TaskPausedEvent(threadId: threadId, taskId: taskId);
      notifyUi(pausedEvent);
    }
    if (status.status == RichStatus.taskCancelled) {
      // 任务取消
      final cancelledEvent = TaskCancelledEvent(threadId: threadId, taskId: taskId);
      notifyUi(cancelledEvent);
    }
    if (status.status == RichStatus.ok) {
      // 任务完成，直接保存结果到文件
      if (responses != null) {
        responses = [...responses!, ...response];
      } else {
        responses = [...response];
      }
    }
  }

  /// [originParams] 原始的批量任务参数
  /// [response] 已完成的任务响应数据，
  Future<void> _savePausedTask(
    List<Map<String, dynamic>> originParams,
    List<Map<String, dynamic>> response,
  ) async {
    String taskPath = await Config.pathTask;
    final pausedFilePath = p.join(taskPath, taskId, ".json");
    final params = originParams.sublist(response.length);
    Map<String, dynamic> result = {};
    result['Params'] = params; // 还未完成的参数列表
    result['TaskId'] = taskId; // 任务ID
    result['ThreadId'] = threadId; // 线程ID
    result['Status'] = status.val; // 任务状态
    result['SubmitTime'] = submitTime.millisecondsSinceEpoch; // 提交时间
    result['Priority'] = priority.val; // 任务优先级
    result['TotalRequests'] = totalRequests; // 任务请求总数
    result['DoneRequests'] = doneRequests; // 已完成任务请求数
    result['OriginTotalRequests'] = originTotalRequests; // 原始任务请求总数
    result['Progress'] = progress; // 任务进度
    result['TaskType'] = type.val; // 任务类型
    result['ApiType'] = apiType.val; // API类型
    result['Responses'] = response; // 已经完成的响应列表
    final data = jsonEncode(result);
    FileTool.saveFile(pausedFilePath, data);
  }

  @override
  Map<String, dynamic> dump() => {};

  // 命名构造函数
  BatchApiTask.build(super.json)
    : doneRequests = json['DoneRequests'] as int,
      originTotalRequests = json['OriginTotalRequests'] as int,
      totalRequests = json['TotalRequests'] as int,
      super.build();

  @override
  void onCancelledIsolate() {
    apiService.cancel();
  }

  @override
  Future<void> onPausedIsolate() async {
    apiService.pause(); // 任务暂停
  }
}
