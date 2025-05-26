// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/isolate_worker.dart
// Purpose:     isolate worker
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:irich/service/tasks/task.dart';
import 'package:irich/service/task_events.dart';

class IsolateWorker {
  final SendPort mainSendPort; // 主线程(UI线程)的消息发送端口
  final int threadId; // 子线程ID
  Isolate? _isolate; // 子线程引用
  SendPort? _isolateSendPort; // 向子线程发送消息的端口
  bool isBusy; // 当前线程有任务执行

  IsolateWorker(this.threadId, this.mainSendPort) : isBusy = false;

  static Future<IsolateWorker> create(SendPort mainSendPort, int threadId) async {
    final worker = IsolateWorker(threadId, mainSendPort);
    await worker._initialize();
    return worker;
  }

  Future<void> _initialize() async {
    // 获取主 Isolate 的 token
    final rootIsolateToken = RootIsolateToken.instance!;
    final initPort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, [
      mainSendPort,
      threadId,
      initPort.sendPort,
      rootIsolateToken,
    ]);
    // 等待子线程返回消息发送端口
    _isolateSendPort = await initPort.first as SendPort;
    initPort.close();
  }

  void notify(UiEvent event) {
    _isolateSendPort?.send(event.serialize());
  }

  Future<void> dispose() async {
    notify(KillWorkerUiEvent(taskId: ""));
    await Future.delayed(const Duration(milliseconds: 100)); // Allow cleanup
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _isolateSendPort = null;
  }

  static void _isolateEntry(List<dynamic> args) {
    // 初始化 BackgroundIsolateBinaryMessenger

    final SendPort mainSendPort = args[0] as SendPort;
    final int threadId = args[1] as int;
    final SendPort initPort = args[2] as SendPort;
    final RootIsolateToken rootIsolateToken = args[3] as RootIsolateToken;

    // 初始化 BackgroundIsolateBinaryMessenger,否则在子进程中无法调用 getApplicationDocumentsDirectory 等方法
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

    final receivePort = ReceivePort();
    // 返回子线程消息发送端口
    initPort.send(receivePort.sendPort);
    Task? currentTask;
    receivePort.listen((dynamic message) async {
      UiEvent event = UiEvent.deserialize(message);
      try {
        if (event is NewTaskEvent) {
          currentTask = event.task;
          currentTask?.mainThread = mainSendPort;
          await _handleNewTask(event, threadId);
          currentTask = null;
        } else if (event is PauseTaskUiEvent) {
          _handlePauseTask(currentTask);
          currentTask = null;
        } else if (event is CancelTaskUiEvent) {
          await _handleCancelTask(event, currentTask, threadId);
          currentTask = null;
        } else if (event is ResumeTaskUiEvent) {
          // 任务恢复过程中，有可能当前任务是另外一个任务正在执行过程中
          // 如果任务当前任务不为空，我们就暂停当前任务，然后再恢复
          if (currentTask != null) {
            currentTask?.status == TaskStatus.running;
            await _handlePauseTask(currentTask);
          }
          // 恢复过程也有可能出错，比如任务暂存文件被删除(超过24小时被清理等情况)
          // 此函数不好封装，因为需要提前返回恢复的Task，在恢复过程中，有可能进程又发来消息，导致竞争
          currentTask = await Task.onResumedIsolate(event.taskId, threadId);

          currentTask?.notifyUi(TaskResumedEvent(threadId: threadId, taskId: event.taskId));
          await currentTask?.run();
          currentTask?.notifyUi(
            TaskCompletedEvent(threadId: threadId, taskId: currentTask!.taskId),
          );
        } else if (event is KillWorkerUiEvent) {
          await _handleKillWorker(mainSendPort, currentTask, threadId);
          receivePort.close();
        }
      } catch (e, stackTrace) {
        _handleError(e, stackTrace, currentTask, threadId);
      }
    });
  }

  /// 处理新任务
  static Future<void> _handleNewTask(NewTaskEvent event, int threadId) async {
    final task = event.task;
    task.notifyUi(TaskStartedEvent(threadId: threadId, taskId: task.taskId));
    try {
      await task.run();
      task.notifyUi(TaskCompletedEvent(threadId: threadId, taskId: task.taskId));
    } catch (e, stackTrace) {
      task.notifyUi(
        TaskErrorEvent(
          threadId: threadId,
          taskId: task.taskId,
          error: e.toString(),
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// 暂停任务
  static Future<void> _handlePauseTask(Task? currentTask) async {
    currentTask?.status = TaskStatus.paused;
    await currentTask?.onPausedIsolate();
  }

  /// 取消任务
  static Future<void> _handleCancelTask(
    CancelTaskUiEvent event,
    Task? currentTask,
    int threadId,
  ) async {
    currentTask?.status = TaskStatus.cancelled;
    currentTask?.onCancelledIsolate();
    currentTask?.notifyUi(TaskCancelledEvent(threadId: threadId, taskId: currentTask.taskId));
  }

  /// 子线程退出
  static Future<void> _handleKillWorker(SendPort mainPort, Task? currentTask, int threadId) async {
    currentTask?.onCancelledIsolate();
    mainPort.send(WorkerExitedEvent(threadId: threadId));
  }

  /// 任务出错
  static void _handleError(dynamic error, StackTrace stackTrace, Task? currentTask, int threadId) {
    currentTask?.notifyUi(
      TaskErrorEvent(
        threadId: threadId,
        taskId: currentTask.taskId,
        error: error.toString(),
        stackTrace: stackTrace,
      ),
    );
  }
}
