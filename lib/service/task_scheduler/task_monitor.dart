// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/task_monitor.dart
// Purpose:     monitor task scheduler tasks' status
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:irich/service/task_scheduler/task.dart';
import 'package:irich/service/task_scheduler/task_scheduler.dart';

class TaskMonitor with ChangeNotifier {
  final TaskScheduler _scheduler = TaskScheduler();
  List<Task> get allTasks => _scheduler.allTasks();
  TaskMonitor() {
    // 定时刷新UI
    Timer.periodic(Duration(seconds: 1), (_) => notifyListeners());
  }

  // 添加爬取任务
  void addTask({required TaskType taskType, TaskPriority priority = TaskPriority.normal}) {
    Task task;
    if (taskType == TaskType.syncIndexDailyKline) {
      task = TaskSyncShareDailyKline(params: {});
    } else {
      throw ArgumentError('Unsupported task type: $taskType');
    }
    _scheduler.addTask(task);
    notifyListeners();
  }

  // 控制任务
  void pauseTask(String taskId) {
    _scheduler.pauseTask(taskId);
    notifyListeners();
  }

  void cancelTask(String taskId) {
    _scheduler.cancelTask(taskId);
    notifyListeners();
  }

  void resumeTask(String taskId) {
    _scheduler.resumeTask(taskId);
    notifyListeners();
  }
}
