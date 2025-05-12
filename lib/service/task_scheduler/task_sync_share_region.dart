// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/task_sync_share_region.dart
// Purpose:     synchronize share region task
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/service/task_scheduler/task.dart';

class TaskSyncShareRegion<R> extends Task<R> {
  TaskSyncShareRegion({
    required super.type,
    required super.params,
    super.priority,
    super.submitTime,
    super.status,
  });
  @override
  Future<R> run() {
    throw UnimplementedError("TaskSyncShareRegion must implement run()");
  }
}
