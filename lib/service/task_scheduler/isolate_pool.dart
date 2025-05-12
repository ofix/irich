// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/isolate_pool.dart
// Purpose:     isolate pool
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:irich/service/task_scheduler/task.dart';
import 'package:irich/service/task_scheduler/isolate_worker.dart';

class IsolatePool {
  final int _minIsolates;
  final int _maxIsolates;
  final Duration _idleTimeout;

  final List<IsolateWorker> _idleWorkers = [];
  final PriorityQueue<Task> _pendingTasks = PriorityQueue(
    (a, b) => a.priority.compareTo(b.priority),
  );
  final List<IsolateWorker> _activeWorkers = [];

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
    for (int i = 0; i < _minIsolates; i++) {
      await _spawnWorker();
    }
  }

  Future<void> execute<R>(Task<R> task) {
    _pendingTasks.add(task);
    _checkPendingTasks();
    return Future.value();
  }

  void _checkPendingTasks() {
    while (_pendingTasks.isNotEmpty && _idleWorkers.isNotEmpty) {
      final task = _pendingTasks.removeFirst();
      final worker = _idleWorkers.removeLast();
      worker.execute(task);
      _activeWorkers.add(worker);
    }

    if (_shouldSpawnMoreWorkers) {
      _spawnWorker();
    }
  }

  bool get _shouldSpawnMoreWorkers =>
      _pendingTasks.isNotEmpty &&
      _pendingTasks.length > _idleWorkers.length &&
      _activeWorkers.length + _idleWorkers.length < _maxIsolates;

  Future<void> _spawnWorker() async {
    final worker = await IsolateWorker.create(_onWorkerIdle);
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
  }
}
