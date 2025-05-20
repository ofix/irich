// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/task_scheduler.dart
// Purpose:     task scheduler for time consuming tasks
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:irich/global/config.dart';
import 'dart:io';
import 'package:irich/service/task_scheduler/isolate_worker.dart';
import 'package:irich/service/task_scheduler/task.dart';
import 'package:irich/service/task_scheduler/task_events.dart';
import 'package:irich/utils/file_tool.dart';

class TaskScheduler {
  final Map<String, Task<dynamic>> _taskMap = {}; // 任务ID => task 的映射列表
  final PriorityQueue<Task> _pendingTaskQueue = PriorityQueue(
    (a, b) => a.priority.compareTo(b.priority),
  ); // 优先级任务等待队列
  final List<Task<dynamic>> taskList = []; // 任务列表，返回给UI显示的副本
  final List<Task<dynamic>> runningTaskList = []; // 运行中的任务列表

  int runningTaskCount = 0; // 运行中任务计数
  int? maxUiRunningTasks = 2; // UI主线程中支持的并发异步任务数
  int? maxPoolRunningTasks = 2; // 线程池中支持的并发异步任务数

  late int minIsolates; // 最小线程数
  late int maxIsolates; // 最大线程数
  late Duration idleTimeout; // 线程空闲超时时间，超过后将回收空闲线程
  ReceivePort? _mainRecvPort; // 线程池通信端口（ui主线程）
  int _nextThreadId = 0; // 子线程ID
  int _runningTaskCount = 0; // 当前运行的任务总数
  int maxConcurrentTasks = 6; // // 主线程+子线程最大并发数

  SendPort get mainSendPort => _mainRecvPort!.sendPort;

  final List<IsolateWorker> _idleWorkers = []; // 空闲子线程列表
  final List<IsolateWorker> _activeWorkers = []; // 活动子线程列表
  final Map<int, IsolateWorker> _workerMap = {}; // 线程ID => Isolate封装类映射表

  //////////////////  UI层 支持 ///////////////////////////
  final List<VoidCallback> _listeners = [];
  Task? _selectedTask;
  Task? get selectedTask => _selectedTask;
  static bool _initialized = false;
  static late TaskScheduler _instance;

  // 单例模式
  factory TaskScheduler({int? maxUiRunningTasks, int? maxPoolRunningTasks}) {
    if (!_initialized) {
      final maxTasks = maxUiRunningTasks ?? Platform.numberOfProcessors ~/ 2;
      _instance = TaskScheduler._internal(
        maxUiRunningTasks: maxTasks,
        maxPoolRunningTasks: maxTasks,
        minIsolates: maxTasks < 2 ? 2 : maxTasks,
        maxIsolates: maxTasks < 2 ? 2 : maxTasks,
        idleTimeout: const Duration(seconds: 60),
      );
      _initialized = true;
    }
    return _instance;
  }

  TaskScheduler._internal({
    required this.maxUiRunningTasks,
    required this.maxPoolRunningTasks,
    required this.minIsolates,
    required this.maxIsolates,
    required this.idleTimeout,
  }) {
    _initialize();
  }

  Future<void> _initialize() async {
    _mainRecvPort = ReceivePort("task_scheduler");
    for (int i = 0; i < minIsolates; i++) {
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
            _pendingTaskQueue.add(task);
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
    return _taskMap[taskId];
  }

  // 处理子线程发送过来的UiEvent
  void listenIsolateEvents() {
    _mainRecvPort?.listen((dynamic message) async {
      final event = jsonDecode(message);
      if (event is TaskStartedEvent) {
        Task? task = _searchTask(event);
        task?.onStartedUi(event);
      } else if (event is TaskProgressEvent) {
        Task? task = _searchTask(event);
        task?.onProgressUi(event);
      } else if (event is TaskPausedEvent) {
        Task? task = _searchTask(event);
        task?.status = TaskStatus.paused;
        _onWorkerIdle(getIsolateWorker(task!.threadId)!);
        _removeRunningTask(task.taskId);
      } else if (event is TaskErrorEvent) {
        Task? task = _searchTask(event);
        task?.status = TaskStatus.failed;
        _removeRunningTask(task!.taskId);
        _onWorkerIdle(getIsolateWorker(task.threadId)!);
      } else if (event is TaskCompletedEvent) {
        Task? task = _searchTask(event);
        task?.onCompletedUi(event, null);
        _removeRunningTask(task!.taskId);
        _onWorkerIdle(getIsolateWorker(task.threadId)!);
      } else if (event is TaskResumedEvent) {
        Task? task = _searchTask(event);
        task?.status = TaskStatus.running;
      } else if (event is TaskCancelledEvent) {
        Task? task = _searchTask(event);
        task?.status = TaskStatus.cancelled;
        _removeRunningTask(task!.taskId);
      }
    });
  }

  IsolateWorker? getIsolateWorker(int threadId) {
    return _workerMap[threadId];
  }

  // 根据任务ID找到对应的任务
  Task? getTaskById(String taskId) {
    return _taskMap[taskId];
  }

  // 提交任务
  Future<T> addTask<T>(Task<T> task) async {
    // 检查任务类型
    if (task.priority == TaskPriority.immediate) {
      // 需要在UI线程中运行的任务需要赋予 immediate 优先级
      final completer = Completer<T>(); // 通过 Completer 包裹后才能拿到任务的结果
      task.completer = completer;
      _pendingTaskQueue.add(task);
      _taskMap[task.taskId] = task;
      taskList.add(task);
      _schedule();
      notifyListeners();
      return completer.future;
    } else {
      _pendingTaskQueue.add(task);
      _taskMap[task.taskId] = task;
      taskList.add(task);
      _schedule();
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
    final task = getTaskById(taskId);
    if (task == null) {
      return false; // 任务不存在
    }
    if (!task.canPaused) {
      return false; // 任务不可以暂停
    }
    task.status = TaskStatus.paused;
    final threadId = task.threadId;
    if (threadId == 0) {
      // 任务没有在子线程执行
      return false;
    }
    final isolateWorker = _workerMap[threadId]; // 找到任务所在子线程
    if (isolateWorker == null) {
      return false;
    }
    final pauseTaskEvent = PauseTaskUiEvent(taskId: taskId); // 通知子线程暂停任务
    isolateWorker.notify(pauseTaskEvent);
    notifyListeners();
    return true;
  }

  // 恢复任务
  bool resumeTask(String taskId) {
    final task = getTaskById(taskId);
    if (task == null) {
      return false; // 任务不存在
    }
    task.status = TaskStatus.paused;
    final threadId = task.threadId;
    if (threadId == 0) {
      // 任务没有在子线程执行
      return false;
    }
    final isolateWorker = _workerMap[threadId]; // 找到任务所在子线程
    if (isolateWorker == null) {
      return false;
    }
    final cancelTaskEvent = ResumeTaskUiEvent(taskId: taskId); // 通知子线程暂停任务
    isolateWorker.notify(cancelTaskEvent);
    notifyListeners();
    return true;
  }

  // 取消任务
  bool cancelTask(String taskId) {
    final task = getTaskById(taskId);
    if (task == null) {
      return false; // 任务不存在
    }
    if (!task.canCancelled) {
      return false; // 任务不可以取消
    }
    task.status = TaskStatus.paused;
    final threadId = task.threadId;
    if (threadId == 0) {
      return false; // 任务没有在子线程执行
    }
    final isolateWorker = _workerMap[threadId]; // 找到任务所在子线程
    if (isolateWorker == null) {
      return false;
    }
    final cancelTaskEvent = CancelTaskUiEvent(taskId: taskId); // 通知子线程暂停任务
    isolateWorker.notify(cancelTaskEvent);
    notifyListeners();
    return true;
  }

  /// 在主线程运行任务
  Future<void> _runTaskInMain(Task<dynamic> task) async {
    _runningTaskCount++;
    final startedEvent = TaskStartedEvent(threadId: 0, taskId: task.taskId);
    task.onStartedUi(startedEvent);
    runningTaskList.add(task);
    final runningTaskIndex = runningTaskList.length - 1;
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
      runningTaskList.removeAt(runningTaskIndex);
    } finally {
      runningTaskList.removeAt(runningTaskIndex);
      _runningTaskCount--;
      _schedule();
    }
  }

  /// 在子线程运行任务
  Future<void> _runTaskInWorker(Task<dynamic> task) async {
    if (!_idleWorkers.isNotEmpty) {
      // 空闲线程不够，看能不能生成一个
      if (_activeWorkers.length + _idleWorkers.length < maxIsolates) {
        _spawnWorker(_nextThreadId++);
      }
    }

    if (!_idleWorkers.isNotEmpty) {
      _pendingTaskQueue.add(task); // 无可用k空闲线程，重新入队
      return;
    }

    _runningTaskCount++; // 在子线程中运行任务
    final worker = _idleWorkers.removeLast();
    task.threadId = worker.threadId; // 将 threadId 赋值给Task
    final newTaskEvent = NewTaskEvent(task: task);
    worker.notify(newTaskEvent);
    _activeWorkers.add(worker);
    _runningTaskCount++;
    runningTaskList.add(task);
  }

  void _removeRunningTask(String taskId) {
    for (int i = 0; i < runningTaskList.length; i++) {
      if (runningTaskList[i].taskId == taskId) {
        runningTaskList.removeAt(i);
        break;
      }
    }
    _runningTaskCount--;
  }

  /// 任务调度
  /// 1. 如果任务优先级为immediate，则在主线程中运行
  /// 2. 其他任务则分配给子线程运行
  void _schedule() async {
    if (_pendingTaskQueue.isEmpty || _runningTaskCount >= maxConcurrentTasks) {
      return; // 无任务或已达最大并发数
    }
    final task = _pendingTaskQueue.removeFirst();
    if (task.priority == TaskPriority.immediate) {
      _runTaskInMain(task);
    } else {
      _runTaskInWorker(task);
    }
  }

  // 创建新线程
  Future<void> _spawnWorker(int threadId) async {
    final worker = await IsolateWorker.create(_mainRecvPort!.sendPort, threadId);
    _idleWorkers.add(worker);
  }

  void _onWorkerIdle(IsolateWorker worker) {
    _activeWorkers.remove(worker);
    _idleWorkers.add(worker);
    _schedule();

    // 闲置超时回收
    Future.delayed(idleTimeout).then((_) {
      if (_idleWorkers.length > minIsolates && _idleWorkers.contains(worker)) {
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
    _workerMap.clear();
    _taskMap.clear();
    _pendingTaskQueue.clear();
    taskList.clear();
  }

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  // 恢复所有暂停的任务
  void resumeAllPausedTask() {
    for (var entry in _taskMap.entries) {
      entry.value.status = TaskStatus.paused;
    }
    notifyListeners();
  }

  Map<String, dynamic> get stats {
    return {
      'waiting': taskList.where((t) => t.status == TaskStatus.pending).length,
      'running': taskList.where((t) => t.status == TaskStatus.running).length,
      'completed': taskList.where((t) => t.status == TaskStatus.completed).length,
      'error': taskList.where((t) => t.status == TaskStatus.failed).length,
      //'totalSpeed': tasks.fold(0, (sum, task) => sum + task.speed),
    };
  }
}
