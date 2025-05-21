// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/tasks/task_sync_share_bk.dart
// Purpose:     synchronize share provinces/concepts/industries
// Author:      songhuabiao
// Created:     2025-05-16 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////\

import 'dart:async';
import 'package:irich/service/api_provider_capabilities.dart';
import 'package:irich/service/api_service.dart';
import 'package:irich/service/tasks/task.dart';

class TaskSyncShareBk extends Task {
  @override
  TaskType type = TaskType.syncShareQuote;
  TaskSyncShareBk({
    required super.params,
    super.priority = TaskPriority.immediate,
    super.submitTime,
    super.status,
  });

  factory TaskSyncShareBk.deserialize(Map<String, dynamic> json) {
    return TaskSyncShareBk(
      params: json['Params'] as Map<String, dynamic>,
      priority: TaskPriority.fromVal(json['Priority'] as int),
      submitTime: DateTime.fromMicrosecondsSinceEpoch(json['SubmitTime']),
      status: TaskStatus.fromVal(json['Status'] as int),
    );
  }

  @override
  Future<List<List<Map<String, dynamic>>>> run() async {
    final (statusBk, resultBk as List<List<Map<String, dynamic>>>) = await ApiService(
      ProviderApiType.quoteExtra,
    ).fetch("");
    if (statusBk.ok()) {
      return resultBk;
    }
    return [];
  }
}
