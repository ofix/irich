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
import 'dart:isolate';

import 'package:irich/service/task_scheduler/isolate_pool.dart';
import 'package:irich/service/task_scheduler/isolate_worker.dart';
import 'package:irich/service/task_scheduler/task.dart';
import 'package:irich/service/task_scheduler/task_events.dart';
import 'package:irich/service/trading_calendar.dart';

class TaskScheduler {
  final Map<TaskType, IsolateWorker> _dedicatedWorkers = {};
  final IsolatePool _isolatePool = IsolatePool(); // 计算密集型子线程
  final _streamControllers = <TaskType, StreamController<IsolateEvent>>{};
  final TradingCalendar _calendar = TradingCalendar();

  void init() {
    // UI线程（主Isolate）
    final receivePort = ReceivePort();
    // isolate.send(receivePort.sendPort);
    receivePort.listen((event) {
      // 处理来自子Isolate的消息
      // 不需要同步锁，因为这是单线程事件循环
    });
  }

  // 任务队列
  final PriorityQueue<Task> _taskQueue = PriorityQueue<Task>(
    (a, b) => b.priority.index.compareTo(a.priority.index),
  );

  final Map<String, Task> _runningTasks = {}; // 运行中的任务
  // 单例模式
  static final TaskScheduler _instance = TaskScheduler._internal();
  factory TaskScheduler() => _instance;
  TaskScheduler._internal();
  // 监听子线程消息
  final ReceivePort _mainReceivePort = ReceivePort();

  Stream<IsolateEvent> getStream(TaskType type) {
    return _streamControllers.putIfAbsent(type, () => StreamController.broadcast()).stream;
  }

  void notify(IsolateEvent event) {
    final controller = _streamControllers[event];
    controller?.add(event);
  }

  // 初始化专用isolate
  Future<void> initialize() async {
    // // 为高优先级任务创建专用isolate
    // _dedicatedWorkers[TaskType.smartShareAnalysis] = await _isolatePool.create();

    // // ...其他专用worker
    // _mainReceivePort.listen(_handleWorkerMessage);
  }

  // 提交任务
  Future<void> addTask(Task task) async {
    _taskQueue.add(task);
    _scheduleTasks();
  }

  // 任务调度
  void _scheduleTasks() {
    while (_runningTasks.length < 3 && _taskQueue.isNotEmpty) {
      final task = _taskQueue.removeFirst();
      if (task.status == TaskStatus.pending || task.status == TaskStatus.paused) {}
    }
  }

  List<Task> allTasks() {
    List<Task> tasks = [];
    return tasks;
  }

  // 暂停任务
  void pauseTask(String taskId) {}

  // 取消任务
  void cancelTask(String taskId) {}

  // 恢复暂停的任务
  void resumeTask(String taskId) {}

  // 重试失败的任务
  void retryTask(String taskId) {}
}
