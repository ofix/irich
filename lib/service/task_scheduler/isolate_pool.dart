// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/isolate_pool.dart
// Purpose:     isolate pool
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:irich/global/config.dart';
import 'package:irich/service/task_scheduler/task.dart';
import 'package:irich/service/task_scheduler/isolate_worker.dart';
import 'package:irich/service/task_scheduler/task_events.dart';
import 'package:irich/utils/file_tool.dart';

class IsolatePool {
  final int _minIsolates; // 最小线程数
  final int _maxIsolates; // 最大线程数
  final Duration _idleTimeout; // 线程空闲超时时间，超过后将回收空闲线程
  ReceivePort? _poolRecvPort; // 线程池通信端口（ui主线程）
  int _nextThreadId = 0; // 子线程ID

  final PriorityQueue<Task> _pendingTasks = PriorityQueue(
    (a, b) => a.priority.compareTo(b.priority),
  ); // 优先级任务队列

  SendPort get poolSendPort => _poolRecvPort!.sendPort;

  final List<IsolateWorker> _idleWorkers = []; // 空闲子线程列表
  final List<IsolateWorker> _activeWorkers = []; // 活动子线程列表
  final Map<int, IsolateWorker> _workersMap = {}; // 线程ID => 线程映射表
  final Map<String, Task> _allTasks = {}; // 任务ID => 任务映射表(全量任务)

  IsolatePool({
    int minIsolates = 2,
    int maxIsolates = 4,
    Duration idleTimeout = const Duration(seconds: 30),
  }) : _minIsolates = minIsolates,
       _maxIsolates = maxIsolates,
       _idleTimeout = idleTimeout {
    _initialize();
  }

  Future<void> _initialize() async {
    _poolRecvPort = ReceivePort("irich_pool");
    for (int i = 0; i < _minIsolates; i++) {
      await _spawnWorker(_nextThreadId++);
    }
    listenIsolateEvents();
    await checkPausedTaskInFileSystem();
  }

  // 检查缓存目录中是否有近24小时暂停的任务
  Future<void> checkPausedTaskInFileSystem() async {
    final targetPath = await Config.pathTask;
    final dir = Directory(targetPath);
    try {
      // 异步列出所有文件和子目录
      await for (var item in dir.list(recursive: false)) {
        if (item is File) {
          // 获取文件状态（包含修改时间）
          final stat = await item.stat();
          final modifiedTime = stat.modified;
          // 计算当前时间与修改时间的差值
          final difference = DateTime.now().difference(modifiedTime);
          // 检查是否超过24小时
          if (difference.inHours <= 24) {
            final data = await FileTool.loadFile(item.path);
            Map<String, dynamic> json = jsonDecode(data);
            Task task = Task.deserialize(json);
            task.status = TaskStatus.paused; // 强制任务暂停
            _pendingTasks.add(task);
          }
        }
      }
    } catch (e) {
      debugPrint('初始化暂停任务失败: $e');
    }
  }

  // 工具函数，根据任务ID找到对应的任务
  Task? _searchTask(IsolateEvent event) {
    String taskId = event.taskId;
    Task? task = _allTasks[taskId];
    return task;
  }

  // 处理子线程发送过来的UiEvent
  void listenIsolateEvents() {
    _poolRecvPort?.listen((dynamic message) async {
      final event = jsonDecode(message);
      if (event is SendPortIsolateEvent) {
        final isolateWorker = _workersMap[event.threadId]; // 找到对应子线程的 worker
        isolateWorker?.isolateSendPort = event.isolateSendPort; // 子线程的消息发送端口
      } else if (event is TaskStartedEvent) {
        Task? task = _searchTask(event);
        task?.onStartedUi(event);
      } else if (event is TaskProgressEvent) {
        Task? task = _searchTask(event);
        task?.onProgressUi(event);
      } else if (event is TaskPausedEvent) {
        Task? task = _searchTask(event);
        task?.status = TaskStatus.paused;
        _onWorkerIdle(getIsolateWorker(task!.threadId)!);
      } else if (event is TaskErrorEvent) {
        Task? task = _searchTask(event);
        task?.status = TaskStatus.failed;
        _onWorkerIdle(getIsolateWorker(task!.threadId)!);
      } else if (event is TaskCompletedEvent) {
        Task? task = _searchTask(event);
        task?.onCompletedUi(event, null);
        _onWorkerIdle(getIsolateWorker(task!.threadId)!);
      } else if (event is TaskResumedEvent) {}
    });
  }

  IsolateWorker? getIsolateWorker(int threadId) {
    return _workersMap[threadId];
  }

  // 发送新任务到空闲线程
  void addTask(Task task) {
    _pendingTasks.add(task);
    _checkPendingTasks();
  }

  // 恢复所有暂停的任务
  void resumePausedTasks() {
    _checkPendingTasks();
  }

  List<Task> allTasks() {
    return _allTasks.values.toList();
  }

  // 根据任务ID找到对应的任务
  Task? getTaskById(String taskId) {
    return _allTasks[taskId];
  }

  // 暂停任务
  bool pauseTask(String taskId) {
    final task = getTaskById(taskId);
    if (task == null) {
      // 任务不存在
      return false;
    }
    task.status = TaskStatus.paused;
    final threadId = task.threadId;
    if (threadId == 0) {
      // 任务没有在子线程执行
      return false;
    }
    final isolateWorker = _workersMap[threadId]; // 找到任务所在子线程
    if (isolateWorker == null) {
      return false;
    }
    final pauseTaskEvent = PauseTaskUiEvent(taskId: taskId); // 通知子线程暂停任务
    isolateWorker.notify(pauseTaskEvent);
    return true;
  }

  // 恢复任务
  bool resumeTask(String taskId) {
    final task = getTaskById(taskId);
    if (task == null) {
      // 任务不存在
      return false;
    }
    task.status = TaskStatus.paused;
    final threadId = task.threadId;
    if (threadId == 0) {
      // 任务没有在子线程执行
      return false;
    }
    final isolateWorker = _workersMap[threadId]; // 找到任务所在子线程
    if (isolateWorker == null) {
      return false;
    }
    final cancelTaskEvent = ResumeTaskUiEvent(taskId: taskId); // 通知子线程暂停任务
    isolateWorker.notify(cancelTaskEvent);
    return true;
  }

  // 取消任务
  bool cancelTask(String taskId) {
    final task = getTaskById(taskId);
    if (task == null) {
      // 任务不存在
      return false;
    }
    task.status = TaskStatus.paused;
    final threadId = task.threadId;
    if (threadId == 0) {
      // 任务没有在子线程执行
      return false;
    }
    final isolateWorker = _workersMap[threadId]; // 找到任务所在子线程
    if (isolateWorker == null) {
      return false;
    }
    final cancelTaskEvent = CancelTaskUiEvent(taskId: taskId); // 通知子线程暂停任务
    isolateWorker.notify(cancelTaskEvent);
    return true;
  }

  void _checkPendingTasks() {
    while (_pendingTasks.isNotEmpty && _idleWorkers.isNotEmpty) {
      final task = _pendingTasks.removeFirst();
      final worker = _idleWorkers.removeLast();
      task.threadId = worker.threadId; // 将 threadId 赋值给Task
      final newTaskEvent = NewTaskEvent(task: task);
      worker.notify(newTaskEvent);
      _activeWorkers.add(worker);
    }

    if (_shouldSpawnMoreWorkers) {
      _spawnWorker(_nextThreadId++);
    }
  }

  bool get _shouldSpawnMoreWorkers =>
      _pendingTasks.isNotEmpty &&
      _pendingTasks.length > _idleWorkers.length &&
      _activeWorkers.length + _idleWorkers.length < _maxIsolates;

  Future<void> _spawnWorker(int threadId) async {
    final worker = await IsolateWorker.create(this, threadId);
    _idleWorkers.add(worker);
    _checkPendingTasks();
  }

  void _onWorkerIdle(IsolateWorker worker) {
    _activeWorkers.remove(worker);
    _idleWorkers.add(worker);
    _checkPendingTasks();

    // 闲置超时回收
    Future.delayed(_idleTimeout).then((_) {
      if (_idleWorkers.length > _minIsolates && _idleWorkers.contains(worker)) {
        _idleWorkers.remove(worker);
        worker.dispose();
      }
    });
  }

  Future<void> close() async {
    await Future.wait([
      ..._idleWorkers.map((w) => w.dispose()),
      ..._activeWorkers.map((w) => w.dispose()),
    ]);
    _idleWorkers.clear();
    _activeWorkers.clear();
    _workersMap.clear();
    _allTasks.clear();
  }
}
