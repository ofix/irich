// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/task_sync_share_region.dart
// Purpose:     synchronize share region task
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/service/task_scheduler/task.dart';

class TaskSyncShareRegion extends Task {
  @override
  TaskType type = TaskType.syncShareRegion;
  TaskSyncShareRegion({required super.params, super.priority, super.submitTime, super.status});

  factory TaskSyncShareRegion.deserialize(Map<String, dynamic> json) {
    return TaskSyncShareRegion(
      params: json['params'] as Map<String, dynamic>,
      priority: TaskPriority.fromVal(json['priority'] as int),
      submitTime: DateTime.fromMillisecondsSinceEpoch(json['submitTime'] as int),
      status: TaskStatus.fromVal(json['status'] as int),
    );
  }
  @override
  Future<dynamic> run() {
    throw UnimplementedError("TaskSyncShareRegion must implement run()");
  }
}
