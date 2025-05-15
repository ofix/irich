// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/task_scheduler.dart
// Purpose:     task scheduler for time consuming tasks
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';
import 'package:collection/collection.dart';
import 'dart:io';

import 'package:irich/service/task_scheduler/isolate_pool.dart';
import 'package:irich/service/task_scheduler/task.dart';
import 'package:irich/service/trading_calendar.dart';

class TaskScheduler {
  IsolatePool? _isolatePool; // 计算密集型子线程
  final TradingCalendar _calendar = TradingCalendar(); // 交易日历
  final Map<String, Task> _allTasks = {}; // 所有在UI线程中的任务
  final PriorityQueue<Task> _taskQueue = PriorityQueue<Task>(
    // 任务队列
    (a, b) => b.priority.index.compareTo(a.priority.index),
  );
  int runningTaskCount = 0; // 运行中任务计数
  int? maxRunningTasks; // 支持最大同时运行的任务数（UI任务数+线程池任务数总和）

  // 单例模式
  static final TaskScheduler _instance = TaskScheduler._internal();
  static bool _initialized = false;

  factory TaskScheduler({int? maxRunningTasks}) {
    if (!_initialized) {
      final maxTasks = maxRunningTasks ?? Platform.numberOfProcessors;
      _instance.maxRunningTasks = maxTasks;
      _instance._isolatePool = IsolatePool(
        minIsolates: maxTasks > 2 ? maxTasks - 2 : 2, // 确保至少2个isolate，一个用于IO，一个用于本地计算
        maxIsolates: maxTasks > 2 ? maxTasks - 2 : 2,
      );
      _initialized = true;
    }
    return _instance;
  }

  TaskScheduler._internal();

  // 初始化专用isolate
  Future<void> initialize() async {}

  // 提交任务
  Future<void> addTask(Task task) async {
    _taskQueue.add(task);
    _scheduleTasks();
  }

  // 任务调度
  void _scheduleTasks() {
    while (runningTaskCount < 3 && _taskQueue.isNotEmpty) {
      final task = _taskQueue.removeFirst();
      runningTaskCount += 1;
      if (task.status == TaskStatus.pending || task.status == TaskStatus.paused) {}
    }
    // 调度线程池中的任务
  }

  // 获取所有中的任务（UI中所有异步任务+线程池中的所有异步任务）
  List<Task> allTasks() {
    final tasksInIsolatePool = _isolatePool!.allTasks();
    final tasksInScheduler = _allTasks.values.toList();
    List<Task> mergedTasks =
        (tasksInIsolatePool + tasksInScheduler)
          ..sort((a, b) => a.submitTime.compareTo(b.submitTime));
    return mergedTasks;
  }

  // 根据任务ID获取任务
  Task? getTaskById(String taskId) {
    final taskInUi = _allTasks[taskId];
    if (taskInUi != null) {
      return taskInUi;
    }
    final taskInIsolatePool = _isolatePool!.getTaskById(taskId);
    return taskInIsolatePool;
  }

  // 暂停任务
  bool pauseTask(String taskId) {
    Task? task = _allTasks[taskId];
    if (task != null) {
      task.status = TaskStatus.paused;
      return true;
    }
    task = _isolatePool!.getTaskById(taskId);
    return _isolatePool?.pauseTask(taskId) ?? false;
  }

  // 恢复暂停的任务
  bool resumeTask(String taskId) {
    // 检查当前任务数是否已经超过最大任务数了，如果是先暂停一个

    // 检查任务在线程池还是UI线程
    Task? task = _allTasks[taskId];
    if (task != null) {
      task.status = TaskStatus.running;
      return true;
    }
    task = _isolatePool!.getTaskById(taskId);
    return _isolatePool?.resumeTask(taskId) ?? false;
  }

  // 取消任务
  bool cancelTask(String taskId) {
    Task? task = _allTasks[taskId];
    if (task != null) {
      task.status = TaskStatus.cancelled;
      return true;
    }
    task = _isolatePool!.getTaskById(taskId);
    return _isolatePool?.cancelTask(taskId) ?? false;
  }

  // 恢复所有暂停的任务
  void resumeAllPausedTask() {
    _isolatePool?.resumePausedTasks();
  }
}
