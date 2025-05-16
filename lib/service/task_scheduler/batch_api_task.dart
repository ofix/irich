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

abstract class BatchApiTask extends Task {
  ApiService apiService;
  ProviderApiType get apiType;
  String pausedFilePath;
  List<Map<String, dynamic>> responses;
  BatchApiTask({super.params, super.priority, super.submitTime, super.status})
    : apiService = ApiService(ProviderApiType.unknown),
      pausedFilePath = '',
      responses = [];

  Future<dynamic> doJob() async {
    apiService = ApiService(apiType);
    final result = await apiService.batchFetch(params, (
      Map<String, dynamic> params,
      String providerName,
    ) {
      onProgress(params, providerName);
    });
    String taskPath = await Config.pathTask;
    pausedFilePath = p.join(taskPath, taskId, ".json");
    final (status, response) = result;
    if (status.status == RichStatus.taskPaused) {
      // 任务真的暂停成功
      _savePausedTask(response);
      IsolateEvent pausedEvent = TaskPausedIsolateEvent(threadId, taskId: taskId);
      notifyUiThread(pausedEvent);
    }
    if (status.status == RichStatus.taskCancelled) {
      // 任务取消
      IsolateEvent cancelledEvent = TaskCancelledIsolateEvent(threadId, taskId);
      notifyUiThread(cancelledEvent);
    }
    if (status.status == RichStatus.ok) {
      responses = [...responses, ...response];
    }
  }

  void _savePausedTask(dynamic) {
    final data = jsonEncode(dynamic);
    FileTool.saveFile(pausedFilePath, data);
  }

  @override
  void onCanceledIsolate(String taskId) {}
  @override
  void onPausedIsolate(String taskId) {
    // 任务被取消
    if (taskId != this.taskId) {
      return;
    }
    status = TaskStatus.paused;
    apiService.pause(); // 任务暂停
  }

  @override
  void onResumedIsolate(String taskId) async {
    final data = await FileTool.loadFile(pausedFilePath);
    final json = jsonDecode(data);
    params = json['params']; // 用参数覆盖原有的参数
    responses = json['responses'];
    status = TaskStatus.running;
    await doJob();
    TaskRecoveredIsolateEvent resumeEvent = TaskRecoveredIsolateEvent(threadId, taskId: taskId);
    notifyUiThread(resumeEvent);
  }

  @override
  void onStartedIsolate(String taskId) {}
  @override
  void onDeletedIsolate(String taskId) {}
}
