// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/tasks/task_monitor.dart
// Purpose:     monitor task scheduler tasks' status
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:irich/service/tasks/task.dart';
import 'package:irich/service/task_scheduler.dart';

class TaskMonitor with ChangeNotifier {
  late final TaskScheduler _scheduler; // 延迟初始化
  Timer? _refreshTimer;

  List<Task> get allTasks => _scheduler.taskList;

  // 私有构造函数
  TaskMonitor._internal();

  // 工厂构造函数 + 静态异步初始化方法
  static Future<TaskMonitor> create() async {
    final monitor = TaskMonitor._internal();
    await monitor._initialize();
    return monitor;
  }

  // 异步初始化逻辑
  Future<void> _initialize() async {
    _scheduler = await TaskScheduler.getInstance();
    _startPeriodicRefresh();
  }

  // 启动定时刷新
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 1), (_) => notifyListeners());
  }

  // 添加任务
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

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
