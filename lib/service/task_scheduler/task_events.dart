// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/task_event.dart
// Purpose:     isolate communicate message
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

// 任务事件集合
import 'dart:isolate';

import 'package:irich/service/request_log.dart';
import 'package:irich/service/task_scheduler/task.dart';

// 线程事件类型
const String strTaskProgress = "TaskProgress";
const String strTaskStarted = "TaskStarted";
const String strTaskCompleted = "TaskCompleted";
const String strTaskError = "TaskError";
const String strTaskCancelled = "TaskCancelled";
const String strTaskPaused = "TaskPaused";
const String strTaskResumed = "TaskResumed";
const String strSendPort = "SendPort";
const String strWorkerExited = "WorkerExited";
// UI事件类型
const String strNewTask = "NewTask";
const String strPauseTask = "PauseTask";
const String strCancelTask = "CancelTask";
const String strResumeTask = "ResumeTask";
const String strExitWorker = "ExitWorker";

abstract class IsolateEvent {
  int threadId; // 线程ID
  String taskId; // 任务ID
  String get type; // 事件类型
  final DateTime timestamp; // 增加时间戳

  IsolateEvent({required this.threadId, required this.taskId}) : timestamp = DateTime.now();
  Map<String, dynamic> serialize(); // 序列化

  static IsolateEvent? deserialize(Map<String, dynamic> json) {
    switch (json['Type']) {
      case strTaskProgress:
        return TaskProgressEvent.deserialize(json);
      case strTaskStarted:
        return TaskStartedEvent.deserialize(json);
      case strTaskCompleted:
        return TaskCompletedEvent.deserialize(json);
      case strTaskError:
        return TaskErrorEvent.deserialize(json);
      case strTaskCancelled:
        return TaskCancelledEvent.deserialize(json);
      case strTaskPaused:
        return TaskPausedEvent.deserialize(json);
      case strTaskResumed:
        return TaskResumedEvent.deserialize(json);
      default:
        return null;
    }
  }
}

// 子线程给线程池发送子线程发送端口消息
class SendPortIsolateEvent extends IsolateEvent {
  @override
  final String type = strSendPort;
  SendPort isolateSendPort;
  SendPortIsolateEvent({
    required super.threadId,
    required super.taskId,
    required this.isolateSendPort,
  });
  @override
  Map<String, dynamic> serialize() {
    return {};
  }
}

// 任务取消
class TaskCancelledEvent extends IsolateEvent {
  @override
  final String type = strTaskCancelled;
  TaskCancelledEvent({required super.threadId, required super.taskId});
  @override
  Map<String, dynamic> serialize() => {
    'Type': type,
    'ThreadId': threadId,
    'TaskId': taskId,
    'Timestamp': timestamp.toIso8601String(),
  };
  factory TaskCancelledEvent.deserialize(Map<String, dynamic> json) {
    return TaskCancelledEvent(threadId: json['ThreadId'] as int, taskId: json['TaskId'] as String);
  }
}

// 任务开始事件消息
class TaskStartedEvent extends IsolateEvent {
  @override
  final String type = strTaskStarted;

  TaskStartedEvent({required super.threadId, required super.taskId});

  @override
  Map<String, dynamic> serialize() => {
    'Type': type,
    'ThreadId': threadId,
    'TaskId': taskId,
    'Timestamp': timestamp.toIso8601String(),
  };

  factory TaskStartedEvent.deserialize(Map<String, dynamic> json) {
    return TaskStartedEvent(threadId: json['ThreadId'] as int, taskId: json['TaskId'] as String);
  }
}

// 任务进度事件消息
class TaskProgressEvent extends IsolateEvent {
  @override
  final String type = strTaskProgress;
  final double progress; // 0.0 ~ 1.0
  final List<RequestLog> requestLogs;

  TaskProgressEvent({
    required super.threadId,
    required super.taskId,
    required this.progress,
    required this.requestLogs,
  });

  @override
  Map<String, dynamic> serialize() => {
    'Type': type,
    'TaskId': taskId,
    'Progress': progress,
    'Timestamp': timestamp.toIso8601String(),
    'RequestLogs': RequestLog.serializeList(requestLogs),
  };

  factory TaskProgressEvent.deserialize(Map<String, dynamic> json) {
    return TaskProgressEvent(
      threadId: json['ThreadId'] as int,
      taskId: json['TaskId'] as String,
      progress: (json['Progress'] as num).toDouble(),
      requestLogs: RequestLog.unserializeList(json['RequestLogs']),
    );
  }
}

// 任务完成事件消息
class TaskCompletedEvent extends IsolateEvent {
  @override
  final String type = strTaskCompleted;
  final dynamic result; // 使用泛型更佳

  TaskCompletedEvent({required super.threadId, required super.taskId, this.result});

  @override
  Map<String, dynamic> serialize() => {
    'Type': type,
    'ThreadId': threadId,
    'TaskId': taskId,
    'Result': result,
    'Timestamp': timestamp.toIso8601String(),
  };

  factory TaskCompletedEvent.deserialize(Map<String, dynamic> json) {
    return TaskCompletedEvent(
      threadId: json['ThreadId'] as int,
      taskId: json['TaskId'] as String,
      result: json['Result'],
    );
  }
}

// 任务出错事件消息
class TaskErrorEvent extends IsolateEvent {
  @override
  final String type = strTaskError;
  final String error;
  final StackTrace stackTrace;

  TaskErrorEvent({
    required super.threadId,
    required super.taskId,
    required this.error,
    required this.stackTrace,
  });

  @override
  Map<String, dynamic> serialize() => {
    'Type': type,
    'ThreadId': threadId,
    'TaskId': taskId,
    'Error': error,
    'StackTrace': stackTrace.toString(),
    'Timestamp': timestamp.toIso8601String(),
  };

  factory TaskErrorEvent.deserialize(Map<String, dynamic> json) {
    return TaskErrorEvent(
      threadId: json['ThreadId'] as int,
      taskId: json['TaskId'] as String,
      error: json['Error'] as String,
      stackTrace: StackTrace.fromString(json['StackTrace'] as String),
    );
  }
}

// 任务出错事件消息
class TaskPausedEvent extends IsolateEvent {
  @override
  final String type = strTaskPaused;

  TaskPausedEvent({required super.threadId, required super.taskId});

  @override
  Map<String, dynamic> serialize() => {
    'Type': type,
    'ThreadId': threadId,
    'TaskId': taskId,
    'Timestamp': timestamp.toIso8601String(),
  };

  factory TaskPausedEvent.deserialize(Map<String, dynamic> json) {
    return TaskPausedEvent(threadId: json['ThreadId'] as int, taskId: json['TaskId'] as String);
  }
}

// 任务恢复
class TaskResumedEvent extends IsolateEvent {
  @override
  final String type = strTaskResumed;

  TaskResumedEvent({required super.threadId, required super.taskId});
  @override
  Map<String, dynamic> serialize() => {
    'Type': type,
    'ThreadId': threadId,
    'TaskId': taskId,
    'Timestamp': timestamp.toIso8601String(),
  };

  factory TaskResumedEvent.deserialize(Map<String, dynamic> json) {
    return TaskResumedEvent(threadId: json['ThreadId'], taskId: json['TaskId'] as String);
  }
}

// 子线程成功退出消息
class WorkerExitedEvent extends IsolateEvent {
  @override
  final String type = strWorkerExited;

  WorkerExitedEvent({required super.threadId, super.taskId = ""});
  @override
  Map<String, dynamic> serialize() => {
    'Type': type,
    'ThreadId': threadId,
    'TaskId': taskId,
    'Timestamp': timestamp.toIso8601String(),
  };
}

// UI 主线程事件消息
abstract class UiEvent {
  String get type;
  final DateTime timestamp = DateTime.now();

  Map<String, dynamic> serialize();

  static UiEvent? deserialize(Map<String, dynamic> json) {
    switch (json['Type']) {
      case strPauseTask:
        return PauseTaskUiEvent.deserialize(json);
      case strResumeTask:
        return ResumeTaskUiEvent.deserialize(json);
      case strCancelTask:
        return CancelTaskUiEvent.deserialize(json);
      default:
        return null;
    }
  }
}

class NewTaskEvent extends UiEvent {
  @override
  final String type = strNewTask;
  final Task task;
  NewTaskEvent({required this.task});

  @override
  Map<String, dynamic> serialize() => {'Type': type, "Task": task.serialize()};
}

// 暂停任务事件消息
class PauseTaskUiEvent extends UiEvent {
  @override
  final String type = strPauseTask;
  final String taskId;
  final bool immediate; // 是否立即暂停

  PauseTaskUiEvent({required this.taskId, this.immediate = true});

  @override
  Map<String, dynamic> serialize() => {
    'Type': type,
    'TaskId': taskId,
    'Immediate': immediate,
    'Timestamp': timestamp.toIso8601String(),
  };

  factory PauseTaskUiEvent.deserialize(Map<String, dynamic> json) {
    return PauseTaskUiEvent(
      taskId: json['TaskId'] as String,
      immediate: json['Immediate'] as bool? ?? true,
    );
  }
}

// 取消任务事件消息
class CancelTaskUiEvent extends UiEvent {
  @override
  final String type = strCancelTask;
  final String taskId;
  final bool releaseResources;

  CancelTaskUiEvent({required this.taskId, this.releaseResources = true});

  @override
  Map<String, dynamic> serialize() => {
    'Type': type,
    'TaskId': taskId,
    'ReleaseResources': releaseResources,
    'Timestamp': timestamp.toIso8601String(),
  };

  factory CancelTaskUiEvent.deserialize(Map<String, dynamic> json) {
    return CancelTaskUiEvent(
      taskId: json['TaskId'] as String,
      releaseResources: json['ReleaseResources'] as bool? ?? true,
    );
  }
}

// 恢复任务事件消息
class ResumeTaskUiEvent extends UiEvent {
  @override
  final String type = strResumeTask;
  final String taskId;
  ResumeTaskUiEvent({required this.taskId});

  @override
  Map<String, dynamic> serialize() => {
    'Type': type,
    'TaskId': taskId,
    'Timestamp': timestamp.toIso8601String(),
  };

  factory ResumeTaskUiEvent.deserialize(Map<String, dynamic> json) {
    return ResumeTaskUiEvent(taskId: json['TaskId'] as String);
  }
}

// 子线程退出事件消息
class KillWorkerUiEvent extends UiEvent {
  @override
  final String type = strExitWorker;
  final String taskId;
  KillWorkerUiEvent({required this.taskId});

  @override
  Map<String, dynamic> serialize() => {};
}
