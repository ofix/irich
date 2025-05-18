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
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:irich/service/task_scheduler/isolate_pool.dart';
import 'package:irich/service/task_scheduler/task.dart';
import 'package:irich/service/task_scheduler/task_events.dart';

class TaskScheduler {
  IsolatePool? _isolatePool; // 计算密集型子线程
  final Map<String, Task<dynamic>> _tasks = {}; // 所有在UI线程中的任务
  final PriorityQueue<Task<dynamic>> _taskQueue = PriorityQueue<Task<dynamic>>(
    // 任务队列
    (a, b) => b.priority.index.compareTo(a.priority.index),
  );
  final List<Task<dynamic>> _activeTasks = []; // 运行中的任务
  int runningTaskCount = 0; // 运行中任务计数
  int? maxUiRunningTasks; // UI主线程中支持的并发异步任务数
  int? maxPoolRunningTasks; // 线程池中支持的并发异步任务数
  //////////////////  UI层 支持 ///////////////////////////
  final List<VoidCallback> _listeners = [];
  Task? _selectedTask;
  Task? get selectedTask => _selectedTask;

  // 单例模式
  static final TaskScheduler _instance = TaskScheduler._internal();
  static bool _initialized = false;

  factory TaskScheduler({int? maxUiRunningTasks, int? maxPoolRunningTasks}) {
    if (!_initialized) {
      final maxTasks = maxUiRunningTasks ?? Platform.numberOfProcessors ~/ 2;
      _instance.maxUiRunningTasks = maxTasks;
      _instance.maxPoolRunningTasks = maxTasks;
      _instance._isolatePool = IsolatePool(
        minIsolates: maxTasks < 2 ? 2 : maxTasks, // 确保线程池至少2个线程，一个用于IO，一个用于本地计算
        maxIsolates: maxTasks < 2 ? 2 : maxTasks,
      );
      _initialized = true;
    }
    return _instance;
  }

  TaskScheduler._internal();

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  // 获取所有中的任务（UI中所有异步任务+线程池中的所有异步任务）
  List<Task> allTasks() {
    final tasksInIsolatePool = _isolatePool!.allTasks();
    final tasksInScheduler = _tasks.values.toList();
    List<Task> mergedTasks =
        (tasksInIsolatePool + tasksInScheduler)
          ..sort((a, b) => a.submitTime.compareTo(b.submitTime));
    return mergedTasks;
  }

  // 提交任务
  Future<T> addTask<T>(Task<T> task) async {
    // 检查任务类型
    _tasks[task.taskId] = task;
    if (task.priority == TaskPriority.immediate) {
      // 需要再UI线程中运行的任务需要赋予 immediate 优先级
      final completer = Completer<T>(); // 通过 Completer 包裹后才能拿到任务的结果
      task.completer = completer;
      _taskQueue.add(task);
      _scheduleTasks();
      notifyListeners();
      return completer.future;
    } else {
      _isolatePool?.addTask(task); // 添加任务到线程池，由线程池完成任务分派和运行
      notifyListeners();
      return Future.value();
    }
  }

  // 用户选中一个任务
  void selectTask(Task task) {
    _selectedTask = task;
    notifyListeners();
  }

  // 暂停任务
  bool pauseTask(String taskId) {
    Task? task = _tasks[taskId];
    if (task != null) {
      task.status = TaskStatus.paused;
      return true;
    }
    task = _isolatePool!.getTaskById(taskId);
    bool result = _isolatePool?.pauseTask(taskId) ?? false;
    notifyListeners();
    return result;
  }

  // 恢复暂停的任务
  bool resumeTask(String taskId) {
    // 检查当前任务数是否已经超过最大任务数了，如果是先暂停一个

    // 检查任务在线程池还是UI线程
    Task? task = _tasks[taskId];
    if (task != null) {
      task.status = TaskStatus.running;
      return true;
    }
    task = _isolatePool!.getTaskById(taskId);
    bool result = _isolatePool?.resumeTask(taskId) ?? false;
    notifyListeners();
    return result;
  }

  // 取消任务
  bool cancelTask(String taskId) {
    Task? task = _tasks[taskId];
    if (task != null) {
      task.status = TaskStatus.cancelled;
      return true;
    }
    task = _isolatePool!.getTaskById(taskId);
    bool result = _isolatePool?.cancelTask(taskId) ?? false;
    notifyListeners();
    return result;
  }

  // 恢复所有暂停的任务
  void resumeAllPausedTask() {
    _isolatePool?.resumePausedTasks();
    notifyListeners();
  }

  Map<String, dynamic> get stats {
    final tasks = allTasks();
    return {
      'waiting': tasks.where((t) => t.status == TaskStatus.pending).length,
      'running': tasks.where((t) => t.status == TaskStatus.running).length,
      'completed': tasks.where((t) => t.status == TaskStatus.completed).length,
      'error': tasks.where((t) => t.status == TaskStatus.failed).length,
      //'totalSpeed': tasks.fold(0, (sum, task) => sum + task.speed),
    };
  }

  // 根据任务ID获取任务
  Task? getTaskById(String taskId) {
    final taskInUi = _tasks[taskId];
    if (taskInUi != null) {
      return taskInUi;
    }
    final taskInIsolatePool = _isolatePool!.getTaskById(taskId);
    return taskInIsolatePool;
  }

  // 任务调度
  void _scheduleTasks() async {
    while (runningTaskCount < maxUiRunningTasks! && _taskQueue.isNotEmpty) {
      final task = _taskQueue.removeFirst();
      runningTaskCount += 1;
      final startedEvent = TaskStartedEvent(threadId: 0, taskId: task.taskId);
      task.onStartedUi(startedEvent);
      try {
        final result = await task.run();
        final event = TaskCompletedEvent(threadId: 0, taskId: task.taskId);
        task.onCompletedUi(event, result);
      } catch (e, stackTrace) {
        final event = TaskErrorEvent(
          threadId: 0,
          taskId: task.taskId,
          error: e.toString(),
          stackTrace: stackTrace,
        );
        task.onErrorUi(event);
      } finally {
        _activeTasks.remove(task);
        _scheduleTasks();
      }
    }
  }
}
