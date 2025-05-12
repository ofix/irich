// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/task_sync_share_concept.dart
// Purpose:     synchronize share concepts task
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';

import 'package:irich/service/task_scheduler/task.dart';

class TaskSyncShareConcept<R> extends Task<R> {
  TaskSyncShareConcept({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  }) : super(type: TaskType.syncShareConcept);

  @override
  FutureOr<R> run() {
    // 实现同步最新全量股票概念数据
    throw UnimplementedError("TaskSyncShareConcept must implement run()");
  }
}
