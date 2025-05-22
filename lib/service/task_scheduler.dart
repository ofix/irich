// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler.dart
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
import 'package:irich/service/isolate_worker.dart';
import 'package:irich/service/request_log.dart';
import 'package:irich/service/tasks/task.dart';
import 'package:irich/service/task_events.dart';
import 'package:irich/utils/file_tool.dart';

class TaskScheduler {
  final Map<String, Task<dynamic>> _taskMap = {}; // 任务ID => task 的映射列表
  final PriorityQueue<Task> _pendingTaskQueue = PriorityQueue(
    (a, b) => a.priority.compareTo(b.priority),
  ); // 优先级任务等待队列
  final List<Task<dynamic>> taskList = []; // 任务列表，返回给UI显示的副本
  final List<Task<dynamic>> runningTaskList = []; // 运行中的任务列表
  final Map<String, List<RequestLog>> _isolateTaskLogs = {}; // 子线程执行的任务请求日志

  final List<IsolateWorker> _idleWorkers = []; // 空闲子线程列表
  final List<IsolateWorker> _activeWorkers = []; // 活动子线程列表
  final Map<int, IsolateWorker> _workerMap = {}; // 线程ID => 子线程映射表
  late int minIsolates; // 最小线程数
  late int maxIsolates; // 最大线程数
  late Duration idleTimeout; // 线程空闲超时时间，超时后将回收空闲线程
  ReceivePort? _mainRecvPort; // 线程池通信端口（ui主线程）
  int _nextThreadId = 0; // 子线程ID
  SendPort get mainSendPort => _mainRecvPort!.sendPort;

  // 单例模式
  static bool _initialized = false;
  static late TaskScheduler _instance;

  //////////////////  UI层 支持 ///////////////////////////
  final List<VoidCallback> _listeners = [];
  Task? _selectedTask;
  Task? get selectedTask => _selectedTask;

  // 单例模式
  factory TaskScheduler() {
    if (!_initialized) {
      final minTasks = Platform.numberOfProcessors ~/ 2;
      final maxTasks = Platform.numberOfProcessors;
      _instance = TaskScheduler._internal(
        minIsolates: minTasks,
        maxIsolates: maxTasks,
        idleTimeout: const Duration(seconds: 60),
      );
      _initialized = true;
    }
    return _instance;
  }

  TaskScheduler._internal({
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
            taskList.add(task);
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
      final event = IsolateEvent.deserialize(message);
      if (event is TaskStartedEvent) {
        _handleTaskStarted(event);
      } else if (event is TaskProgressEvent) {
        _handleTaskProgress(event);
      } else if (event is TaskPausedEvent) {
        _handleTaskPaused(event);
      } else if (event is TaskErrorEvent) {
        _handleTaskError(event);
      } else if (event is TaskCompletedEvent) {
        _handleTaskCompleted(event);
      } else if (event is TaskResumedEvent) {
        _handleTaskResumed(event);
      } else if (event is TaskCancelledEvent) {
        _handleTaskCancelled(event);
      }
    });
  }

  // 处理任务开始执行事件
  void _handleTaskStarted(TaskStartedEvent event) {
    Task? task = _searchTask(event);
    task?.onStartedUi(event);
    notifyListeners();
  }

  // 处理任务进度事件
  void _handleTaskProgress(TaskProgressEvent event) {
    Task? task = _searchTask(event);
    if (task != null) {
      _isolateTaskLogs.putIfAbsent(task.taskId, () => []).add(event.requestLog); // 添加请求日志
      task.onProgressUi(event);
    }
    notifyListeners();
  }

  // 处理任务暂停事件
  void _handleTaskPaused(TaskPausedEvent event) {
    Task? task = _searchTask(event);
    if (task != null) {
      task.status = TaskStatus.paused;
      task.isProcessing = false;
      _removeRunningTask(task.taskId);
      final isolateWorker = getIsolateWorker(task.threadId);
      if (isolateWorker != null) {
        _onWorkerIdle(isolateWorker);
      }
      notifyListeners();
    }
  }

  // 处理任务报错事件
  void _handleTaskError(TaskErrorEvent event) {
    Task? task = _searchTask(event);
    if (task != null) {
      task.status = TaskStatus.failed;
      task.isProcessing = false;
      _removeRunningTask(task.taskId);
      IsolateWorker? isolateWorker = getIsolateWorker(task.threadId);
      if (isolateWorker != null) {
        _onWorkerIdle(isolateWorker);
      }
      notifyListeners();
    }
  }

  // 处理任务完成事件
  void _handleTaskCompleted(TaskCompletedEvent event) {
    Task? task = _searchTask(event);
    task?.onCompletedUi(event, null);
    _removeRunningTask(task!.taskId);
    IsolateWorker? isolateWorker = getIsolateWorker(task.threadId);
    if (isolateWorker != null) {
      _onWorkerIdle(isolateWorker);
    }
    notifyListeners();
  }

  // 处理任务恢复执行事件
  void _handleTaskResumed(TaskResumedEvent event) {
    Task? task = _searchTask(event);
    task?.status = TaskStatus.running;
    task?.isProcessing = false;
    notifyListeners();
  }

  // 处理任务取消事件
  void _handleTaskCancelled(TaskCancelledEvent event) {
    Task? task = _searchTask(event);
    task?.status = TaskStatus.cancelled;
    if (task != null) {
      _removeRunningTask(task.taskId);
      notifyListeners();
    }
  }

  IsolateWorker? getIsolateWorker(int threadId) {
    return _workerMap[threadId];
  }

  // 根据任务ID找到对应的任务
  Task? getTaskById(String taskId) {
    return _taskMap[taskId];
  }

  // UI显示相关函数集
  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  // 恢复所有暂停的任务
  void resumeAllPausedTask() {
    for (int i = 0; i < taskList.length; i++) {
      taskList[i].status = TaskStatus.paused;
    }
    notifyListeners();
  }

  Map<String, dynamic> get stats {
    return {
      'pending': taskList.where((t) => t.status == TaskStatus.pending).length,
      'running': taskList.where((t) => t.status == TaskStatus.running).length,
      'completed': taskList.where((t) => t.status == TaskStatus.completed).length,
      'error': taskList.where((t) => t.status == TaskStatus.failed).length,
      //'totalSpeed': tasks.fold(0, (sum, task) => sum + task.speed),
    };
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
      return completer.future;
    } else {
      _pendingTaskQueue.add(task);
      _taskMap[task.taskId] = task;
      taskList.add(task);
      _schedule();
      return Future.value();
    }
  }

  // 用户选中一个任务
  void selectTask(Task task) {
    _selectedTask = task;
    notifyListeners();
  }

  // 选中任务的日志列表
  List<RequestLog> selectTaskLogs() {
    if (_isolateTaskLogs.containsKey(_selectedTask?.taskId)) {
      return _isolateTaskLogs[_selectedTask?.taskId]!;
    }
    return [];
  }

  // 暂停任务
  bool pauseTask(String taskId) {
    final task = getTaskById(taskId);
    if (task == null) {
      return false; // 任务不存在
    }
    if (task.priority == TaskPriority.immediate) {
      return false; // 主线程UI任务不可以暂停
    }
    if (task.isProcessing) {
      return false; // 任务正在处理中，不允许继续操作
    }
    final threadId = task.threadId;
    if (threadId == 0) {
      // 任务没有在子线程执行
      return false;
    }
    final isolateWorker = _workerMap[threadId]; // 找到任务所在子线程
    if (isolateWorker == null) {
      return false;
    }
    task.isProcessing = true;
    final pauseTaskEvent = PauseTaskUiEvent(taskId: taskId); // 通知子线程暂停任务
    isolateWorker.notify(pauseTaskEvent);
    return true;
  }

  // 恢复任务
  bool resumeTask(String taskId) {
    final task = getTaskById(taskId);
    if (task == null) {
      return false; // 任务不存在
    }
    if (task.isProcessing) {
      return false; // 任务正在处理中，不允许其他操作
    }
    // 没有空闲线程
    if (_idleWorkers.isEmpty) {
      // 空闲线程不够，看能不能生成一个
      if (_activeWorkers.length + _idleWorkers.length < maxIsolates) {
        _spawnWorker(_nextThreadId++);
        if (_idleWorkers.isNotEmpty) {
          _runTaskInIdleIsolateWorker(task);
          return true;
        }
        return false;
      }
      return false;
    }
    // 有空闲线程
    _runTaskInIdleIsolateWorker(task);
    return true;
  }

  // 将恢复的任务安排在一个空闲线程中重新运行
  void _runTaskInIdleIsolateWorker(Task<dynamic> task) {
    final worker = _idleWorkers.removeLast();
    worker.isBusy = true; // 表示当前有任务在运行
    task.threadId = worker.threadId; // 将 threadId 赋值给Task
    final resumeTaskEvent = ResumeTaskUiEvent(taskId: task.taskId); // 通知子线程暂停任务
    worker.notify(resumeTaskEvent);
    _activeWorkers.add(worker);
    runningTaskList.add(task);
  }

  // 取消任务
  bool cancelTask(String taskId) {
    final task = getTaskById(taskId);
    if (task == null) {
      return false; // 任务不存在
    }
    if (task.priority == TaskPriority.immediate) {
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
    return true;
  }

  /// 在主线程运行任务
  Future<void> _runTaskInMain(Task<dynamic> task) async {
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
      _schedule();
    }
  }

  /// 在子线程运行任务
  Future<void> _runTaskInWorker(Task<dynamic> task) async {
    if (_idleWorkers.isEmpty) {
      // 空闲线程不够，看能不能生成一个
      if (_activeWorkers.length + _idleWorkers.length <= maxIsolates) {
        _spawnWorker(_nextThreadId++);
      }
    }

    if (_idleWorkers.isEmpty) {
      _pendingTaskQueue.add(task); // 无可用k空闲线程，重新入队
      return;
    }

    final worker = _idleWorkers.removeLast();
    worker.isBusy = true; // 表示当前有任务在子线程中运行
    task.threadId = worker.threadId; // 将 threadId 赋值给Task
    final newTaskEvent = NewTaskEvent(task: task);
    worker.notify(newTaskEvent);
    _activeWorkers.add(worker);
    runningTaskList.add(task);
  }

  void _removeRunningTask(String taskId) {
    for (int i = 0; i < runningTaskList.length; i++) {
      if (runningTaskList[i].taskId == taskId) {
        runningTaskList.removeAt(i);
        break;
      }
    }
  }

  /// 任务调度
  /// 1. 如果任务优先级为immediate，则在主线程中运行
  /// 2. 其他任务则分配给子线程运行
  void _schedule() async {
    if (_pendingTaskQueue.isEmpty) {
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
    worker.isBusy = false;
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
    // 清理线程相关数据结构
    await Future.wait([
      ..._idleWorkers.map((w) => w.dispose()),
      ..._activeWorkers.map((w) => w.dispose()),
    ]);
    _idleWorkers.clear();
    _activeWorkers.clear();
    _workerMap.clear();
    // 清理任务相关数据结构
    _taskMap.clear();
    _pendingTaskQueue.clear();
    taskList.clear();
    runningTaskList.clear();
  }
}
