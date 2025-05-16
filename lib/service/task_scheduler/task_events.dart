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

import 'package:irich/service/task_scheduler/task.dart';

abstract class IsolateEvent {
  int threadId; // 线程ID
  String taskId; // 任务ID
  String get type; // 事件类型
  final DateTime timestamp; // 增加时间戳

  IsolateEvent({required this.threadId, required this.taskId}) : timestamp = DateTime.now();
  Map<String, dynamic> serialize(); // 序列化

  static IsolateEvent? deserialize(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'taskProgress':
        return TaskProgressIsolateEvent.deserialize(json);
      case 'taskCompleted':
        return TaskCompletedIsolateEvent.deserialize(json);
      case 'taskError':
        return TaskErrorIsolateEvent.deserialize(json);
      case 'taskCancelled':
        return TaskCancelledIsolateEvent.deserialize(json);
      default:
        return null;
    }
  }
}

// 子线程给线程池发送子线程发送端口消息
class SendPortIsolateEvent extends IsolateEvent {
  @override
  final String type = "isolateSendPort";
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
class TaskCancelledIsolateEvent extends IsolateEvent {
  @override
  final String type = "taskCancelled";
  TaskCancelledIsolateEvent({required super.threadId, required super.taskId});
  @override
  Map<String, dynamic> serialize() => {
    'type': 'taskCancelled',
    'threadId': threadId,
    'taskId': taskId,
    'timestamp': timestamp.toIso8601String(),
  };
  factory TaskCancelledIsolateEvent.deserialize(Map<String, dynamic> json) {
    return TaskCancelledIsolateEvent(
      threadId: json['threadId'] as int,
      taskId: json['taskId'] as String,
    );
  }
}

// 任务开始事件消息
class TaskStartedIsolateEvent extends IsolateEvent {
  @override
  final String type = "taskStarted";

  TaskStartedIsolateEvent({required super.threadId, required super.taskId});

  @override
  Map<String, dynamic> serialize() => {
    'type': "started",
    'threadId': threadId,
    'taskId': taskId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TaskStartedIsolateEvent.deserialize(Map<String, dynamic> json) {
    return TaskStartedIsolateEvent(
      threadId: json['threadId'] as int,
      taskId: json['taskId'] as String,
    );
  }
}

// 任务进度事件消息
class TaskProgressIsolateEvent extends IsolateEvent {
  @override
  final String type = "progress";
  final double progress; // 0.0 ~ 1.0

  TaskProgressIsolateEvent({
    required super.threadId,
    required super.taskId,
    required this.progress,
  });

  @override
  Map<String, dynamic> serialize() => {
    'type': type,
    'taskId': taskId,
    'progress': progress,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TaskProgressIsolateEvent.deserialize(Map<String, dynamic> json) {
    return TaskProgressIsolateEvent(
      threadId: json['threadId'] as int,
      taskId: json['taskId'] as String,
      progress: (json['progress'] as num).toDouble(),
    );
  }
}

// 任务完成事件消息
class TaskCompletedIsolateEvent extends IsolateEvent {
  @override
  final String type = "completed";
  final dynamic result; // 使用泛型更佳

  TaskCompletedIsolateEvent({required super.threadId, required super.taskId, this.result});

  @override
  Map<String, dynamic> serialize() => {
    'type': type,
    'threadId': threadId,
    'taskId': taskId,
    'result': result,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TaskCompletedIsolateEvent.deserialize(Map<String, dynamic> json) {
    return TaskCompletedIsolateEvent(
      threadId: json['threadId'] as int,
      taskId: json['taskId'] as String,
      result: json['result'],
    );
  }
}

// 任务出错事件消息
class TaskErrorIsolateEvent extends IsolateEvent {
  @override
  final String type = "error";
  final String error;
  final StackTrace stackTrace;

  TaskErrorIsolateEvent({
    required super.threadId,
    required super.taskId,
    required this.error,
    required this.stackTrace,
  });

  @override
  Map<String, dynamic> serialize() => {
    'type': type,
    'threadId': threadId,
    'taskId': taskId,
    'error': error,
    'stackTrace': stackTrace.toString(),
    'timestamp': timestamp.toIso8601String(),
  };

  factory TaskErrorIsolateEvent.deserialize(Map<String, dynamic> json) {
    return TaskErrorIsolateEvent(
      threadId: json['threadId'] as int,
      taskId: json['taskId'] as String,
      error: json['error'] as String,
      stackTrace: StackTrace.fromString(json['stackTrace'] as String),
    );
  }
}

// 任务出错事件消息
class TaskPausedIsolateEvent extends IsolateEvent {
  @override
  final String type = "taskPaused";

  TaskPausedIsolateEvent({required super.threadId, required super.taskId});

  @override
  Map<String, dynamic> serialize() => {
    'type': type,
    'threadId': threadId,
    'taskId': taskId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TaskPausedIsolateEvent.deserialize(Map<String, dynamic> json) {
    return TaskPausedIsolateEvent(
      threadId: json['threadId'] as int,
      taskId: json['taskId'] as String,
    );
  }
}

// 任务恢复
class TaskResumedIsolateEvent extends IsolateEvent {
  @override
  final String type = 'taskRecovered';

  TaskResumedIsolateEvent({required super.threadId, required super.taskId});
  @override
  Map<String, dynamic> serialize() => {
    'type': type,
    'threadId': threadId,
    'taskId': taskId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TaskResumedIsolateEvent.deserialize(Map<String, dynamic> json) {
    return TaskResumedIsolateEvent(threadId: json['threadId'], taskId: json['taskId'] as String);
  }
}

// UI 主线程事件消息
abstract class UiEvent {
  String get type;
  final DateTime timestamp = DateTime.now();

  Map<String, dynamic> serialize();

  static UiEvent? deserialize(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'pauseTask':
        return PauseTaskUiEvent.deserialize(json);
      case 'resumeTask':
        return ResumeTaskUiEvent.deserialize(json);
      case 'cancelTask':
        return CancelTaskUiEvent.deserialize(json);
      case 'deleteTask':
        return DeleteTaskUiEvent.deserialize(json);
      default:
        return null;
    }
  }
}

class NewTaskEvent extends UiEvent {
  @override
  final String type = "newTask";
  final Task task;
  NewTaskEvent({required this.task});

  @override
  Map<String, dynamic> serialize() => {'type': type, "task": task.serialize()};
}

// 暂停任务事件消息
class PauseTaskUiEvent extends UiEvent {
  @override
  final String type = "pauseTask";
  final String taskId;
  final bool immediate; // 是否立即暂停

  PauseTaskUiEvent({required this.taskId, this.immediate = true});

  @override
  Map<String, dynamic> serialize() => {
    'type': type,
    'taskId': taskId,
    'immediate': immediate,
    'timestamp': timestamp.toIso8601String(),
  };

  factory PauseTaskUiEvent.deserialize(Map<String, dynamic> json) {
    return PauseTaskUiEvent(
      taskId: json['taskId'] as String,
      immediate: json['immediate'] as bool? ?? true,
    );
  }
}

// 取消任务事件消息
class CancelTaskUiEvent extends UiEvent {
  @override
  final String type = "cancelTask";
  final String taskId;
  final bool releaseResources;

  CancelTaskUiEvent({required this.taskId, this.releaseResources = true});

  @override
  Map<String, dynamic> serialize() => {
    'type': type,
    'taskId': taskId,
    'releaseResources': releaseResources,
    'timestamp': timestamp.toIso8601String(),
  };

  factory CancelTaskUiEvent.deserialize(Map<String, dynamic> json) {
    return CancelTaskUiEvent(
      taskId: json['taskId'] as String,
      releaseResources: json['releaseResources'] as bool? ?? true,
    );
  }
}

// 恢复任务事件消息
class ResumeTaskUiEvent extends UiEvent {
  @override
  final String type = "resumeTask";
  final String taskId;
  ResumeTaskUiEvent({required this.taskId});

  @override
  Map<String, dynamic> serialize() => {
    'type': type,
    'taskId': taskId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ResumeTaskUiEvent.deserialize(Map<String, dynamic> json) {
    return ResumeTaskUiEvent(taskId: json['taskId'] as String);
  }
}

// 删除任务事件
class DeleteTaskUiEvent extends UiEvent {
  @override
  final String type = "deleteTask";
  final String taskId;

  DeleteTaskUiEvent({required this.taskId});

  @override
  Map<String, dynamic> serialize() => {
    'type': type,
    'taskId': taskId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory DeleteTaskUiEvent.deserialize(Map<String, dynamic> json) {
    return DeleteTaskUiEvent(taskId: json['taskId'] as String);
  }
}
