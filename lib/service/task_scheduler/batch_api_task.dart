// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/task_sync_share_region.dart
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
import 'package:irich/service/task_scheduler/task.dart';
import 'package:irich/service/task_scheduler/task_events.dart';
import 'package:irich/utils/file_tool.dart';
import 'package:irich/utils/rich_result.dart';
import 'package:path/path.dart' as p;

abstract class BatchApiTask extends Task<void> {
  @override
  bool canPaused = true;
  @override
  bool canCancelled = true;
  ApiService apiService;
  ProviderApiType get apiType;
  String pausedFilePath;
  int totalRequests; // 任务请求总数
  int recvRequests; // 已完成任务请求数
  BatchApiTask({super.params, super.priority, super.submitTime, super.status})
    : apiService = ApiService(ProviderApiType.unknown),
      pausedFilePath = '',
      totalRequests = (params as List<Map<String, dynamic>>).length,
      recvRequests = 0;

  /// 在子线程中运行
  Future<void> doJob() async {
    apiService = ApiService(apiType);
    final result = await apiService.batchFetch(params, (
      Map<String, dynamic> params,
      String providerName,
    ) {
      recvRequests += 1;
      progress = recvRequests / totalRequests; // 计算进度
      final progressEvent = TaskProgressEvent(
        threadId: threadId,
        taskId: taskId,
        progress: progress,
      );
      notifyUi(progressEvent);
    });
    String taskPath = await Config.pathTask;
    pausedFilePath = p.join(taskPath, taskId, ".json");
    final (status, response) = result;
    if (status.status == RichStatus.taskPaused) {
      // 任务真的暂停成功
      _savePausedTask(params, response);
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
  void _savePausedTask(
    List<Map<String, dynamic>> originParams,
    List<Map<String, dynamic>> response,
  ) {
    final params = originParams.sublist(response.length);
    Map<String, dynamic> result = {};
    result['params'] = params; // 还未完成的参数列表
    result['responses'] = response; // 已经完成的响应列表
    final data = jsonEncode(result);
    FileTool.saveFile(pausedFilePath, data);
  }

  @override
  void onCancelledIsolate() {
    apiService.cancel();
  }

  @override
  Future<void> onPausedIsolate() async {
    apiService.pause(); // 任务暂停
  }
}
