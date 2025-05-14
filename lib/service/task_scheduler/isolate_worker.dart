// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/isolate_worker.dart
// Purpose:     isolate worker
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:convert';
import 'dart:isolate';

import 'package:irich/service/task_scheduler/isolate_pool.dart';
import 'package:irich/service/task_scheduler/task.dart';
import 'package:irich/service/task_scheduler/task_events.dart';

class IsolateWorker {
  static int _threadId = 0; // 线程ID
  Isolate? _isolate; // 子线程
  SendPort? _isolateSendPort; // 子线程的发送端口，可以通过这个端口给子线程发送事件消息

  final IsolatePool? _pool; // 线程池引用
  IsolateWorker(this._pool);

  static Future<IsolateWorker> create(IsolatePool pool, int threadId) async {
    final worker = IsolateWorker(pool);
    await worker._initialize();
    _threadId = threadId;
    return worker;
  }

  int get threadId => _threadId;

  Future<void> _initialize() async {
    _isolate = await Isolate.spawn(_isolateEntry, _pool!.poolSendPort);
  }

  void notify(UiEvent event) {
    _isolateSendPort?.send(event);
  }

  Future<void> dispose() async {
    _isolate?.kill();
    _isolate = null;
    _isolateSendPort = null;
  }

  static void _isolateEntry(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    final sendPortEvent = SendPortIsolateEvent(_threadId, receivePort.sendPort);
    mainSendPort.send(sendPortEvent);

    Task? runningTask;
    receivePort.listen((dynamic message) async {
      final event = jsonDecode(message);
      if (event is NewTaskEvent) {
        // 新任务
        runningTask = event.task;
        // 任务开始事件
        IsolateEvent startedEvent = TaskStartedIsolateEvent(_threadId, runningTask!.taskId);
        runningTask!.notifyUiThread(startedEvent);
        try {
          await runningTask?.run();
        } catch (e, stackTrace) {
          // 发送任务出错事件
          final errorEvent = TaskErrorIsolateEvent(
            _threadId,
            taskId: runningTask!.taskId,
            error: e.toString(),
            stackTrace: stackTrace,
          );
          runningTask!.notifyUiThread(errorEvent);
        }
        // 发送任务完成事件
        final completedEvent = TaskCompletedIsolateEvent(_threadId, taskId: runningTask!.taskId);
        runningTask!.notifyUiThread(completedEvent);
      } else if (event is PauseTaskUiEvent) {
        // 任务暂停
        if (runningTask != null) {
          runningTask!.status = TaskStatus.paused;
          IsolateEvent pausedEvent = TaskPausedIsolateEvent(_threadId, taskId: runningTask!.taskId);
          runningTask!.notifyUiThread(pausedEvent);
        }
      } else if (event is CancelTaskUiEvent) {
        // 任务取消
        if (runningTask != null) {
          runningTask!.status = TaskStatus.cancelled;
          IsolateEvent cancelledEvent = TaskCancelledIsolateEvent(_threadId, runningTask!.taskId);
          runningTask!.notifyUiThread(cancelledEvent);
        }
      } else if (event is RecoverTaskUiEvent) {
        // 任务恢复
        runningTask = event.task;
        IsolateEvent resumedEvent = TaskRecoveredIsolateEvent(
          _threadId,
          taskId: runningTask!.taskId,
        );
        runningTask!.notifyUiThread(resumedEvent);
        try {
          await runningTask?.run();
        } catch (e, stackTrace) {
          // 发送任务出错事件
          final errorEvent = TaskErrorIsolateEvent(
            _threadId,
            taskId: runningTask!.taskId,
            error: e.toString(),
            stackTrace: stackTrace,
          );
          runningTask!.notifyUiThread(errorEvent);
        }
        // 发送任务完成事件
        final completedEvent = TaskCompletedIsolateEvent(_threadId, taskId: runningTask!.taskId);
        runningTask!.notifyUiThread(completedEvent);
      }
    });
  }
}
