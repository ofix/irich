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
  SendPort? isolateSendPort; // 子线程的发送端口，可以通过这个端口给子线程发送事件消息

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
    isolateSendPort?.send(event);
  }

  Future<void> dispose() async {
    _isolate?.kill();
    _isolate = null;
    isolateSendPort = null;
  }

  static void _isolateEntry(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    final sendPortEvent = SendPortIsolateEvent(
      threadId: _threadId,
      taskId: "", // 未使用
      isolateSendPort: receivePort.sendPort,
    );
    mainSendPort.send(sendPortEvent);

    Task? runningTask;
    receivePort.listen((dynamic message) async {
      final event = jsonDecode(message);
      if (event is NewTaskEvent) {
        // 新任务
        runningTask = event.task;
        // 任务开始事件
        IsolateEvent startedEvent = TaskStartedIsolateEvent(
          threadId: _threadId,
          taskId: runningTask!.taskId,
        );
        runningTask!.notifyUi(startedEvent);
        try {
          await runningTask?.run();
        } catch (e, stackTrace) {
          // 发送任务出错事件
          final errorEvent = TaskErrorIsolateEvent(
            threadId: _threadId,
            taskId: runningTask!.taskId,
            error: e.toString(),
            stackTrace: stackTrace,
          );
          runningTask!.notifyUi(errorEvent);
        }
        // 发送任务完成事件
        final completedEvent = TaskCompletedIsolateEvent(
          threadId: _threadId,
          taskId: runningTask!.taskId,
        );
        runningTask!.notifyUi(completedEvent);
      } else if (event is PauseTaskUiEvent) {
        // 任务暂停
        if (runningTask != null) {
          runningTask!.onPausedIsolate();
        }
      } else if (event is CancelTaskUiEvent) {
        // 任务取消
        if (runningTask != null) {
          runningTask!.status = TaskStatus.cancelled;
          IsolateEvent cancelledEvent = TaskCancelledIsolateEvent(
            threadId: _threadId,
            taskId: runningTask!.taskId,
          );
          runningTask!.notifyUi(cancelledEvent);
        }
      } else if (event is ResumeTaskUiEvent) {
        // 任务恢复
        final taskId = event.taskId;
        IsolateEvent resumedEvent = TaskResumedIsolateEvent(threadId: _threadId, taskId: taskId);
        runningTask!.notifyUi(resumedEvent);
        try {
          await runningTask?.run();
        } catch (e, stackTrace) {
          // 发送任务出错事件
          final errorEvent = TaskErrorIsolateEvent(
            threadId: _threadId,
            taskId: runningTask!.taskId,
            error: e.toString(),
            stackTrace: stackTrace,
          );
          runningTask!.notifyUi(errorEvent);
        }
        // 发送任务完成事件
        final completedEvent = TaskCompletedIsolateEvent(
          threadId: _threadId,
          taskId: runningTask!.taskId,
        );
        runningTask!.notifyUi(completedEvent);
      }
    });
  }
}
