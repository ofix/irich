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
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:irich/service/task_scheduler/task.dart';
import 'package:irich/service/task_scheduler/isolate_worker.dart';
import 'package:irich/service/task_scheduler/task_events.dart';

class IsolatePool {
  final int _minIsolates;
  final int _maxIsolates;
  final Duration _idleTimeout;
  ReceivePort? _poolRecvPort;
  int _nextThreadId = 0;

  final PriorityQueue<Task> _pendingTasks = PriorityQueue(
    (a, b) => a.priority.compareTo(b.priority),
  ); // 优先级任务队列

  SendPort get poolSendPort => _poolRecvPort!.sendPort;

  final List<IsolateWorker> _idleWorkers = []; // 空闲子线程
  final List<IsolateWorker> _activeWorkers = []; // 工作子线程
  final Map<int, IsolateWorker> _workersMap = {}; // 线程ID => 线程映射表

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
  }

  // 处理子线程发送过来的UiEvent
  void listenIsolateEvents() {
    _poolRecvPort?.listen((dynamic message) {
      final event = jsonDecode(message);
      if (event is TaskStartedIsolateEvent) {
      } else if (event is TaskProgressIsolateEvent) {
      } else if (event is TaskPausedIsolateEvent) {
      } else if (event is TaskErrorIsolateEvent) {
      } else if (event is TaskCompletedIsolateEvent) {
        _onWorkerIdle(getIsolateWorker(event.threadId)!);
      } else if (event is TaskRecoveredIsolateEvent) {}
    });
  }

  IsolateWorker? getIsolateWorker(int threadId) {
    return _workersMap[threadId];
  }

  Future<void> run<R>(Task<R> task) {
    _pendingTasks.add(task);
    _checkPendingTasks();
    return Future.value();
  }

  void _checkPendingTasks() {
    while (_pendingTasks.isNotEmpty && _idleWorkers.isNotEmpty) {
      final task = _pendingTasks.removeFirst();
      final worker = _idleWorkers.removeLast();
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
  }
}
