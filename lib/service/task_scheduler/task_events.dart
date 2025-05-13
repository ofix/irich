// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/task_event.dart
// Purpose:     isolate communicate message
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

// 任务事件集合
abstract class IsolateEvent {
  String get type; // 事件类型
  final DateTime timestamp; // 增加时间戳

  IsolateEvent() : timestamp = DateTime.now();
  Map<String, dynamic> serialize(); // 序列化

  static IsolateEvent? deserialize(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'progress':
        return TaskProgressIsolateEvent.deserialize(json);
      case 'completed':
        return TaskCompletedIsolateEvent.deserialize(json);
      case 'error':
        return TaskErrorIsolateEvent.deserialize(json);
      default:
        return null;
    }
  }
}

// 任务开始事件消息
class TaskStartedIsolateEvent extends IsolateEvent {
  @override
  final String type = "started";
  String taskId;

  TaskStartedIsolateEvent(this.taskId);

  @override
  Map<String, dynamic> serialize() => {
    'type': "started",
    'taskId': taskId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TaskStartedIsolateEvent.deserialize(Map<String, dynamic> json) {
    return TaskStartedIsolateEvent(json['taskId'] as String);
  }
}

// 任务进度事件消息
class TaskProgressIsolateEvent extends IsolateEvent {
  @override
  final String type = "progress";
  final String taskId;
  final double progress; // 0.0 ~ 1.0

  TaskProgressIsolateEvent({required this.taskId, required this.progress});

  @override
  Map<String, dynamic> serialize() => {
    'type': type,
    'taskId': taskId,
    'progress': progress,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TaskProgressIsolateEvent.deserialize(Map<String, dynamic> json) {
    return TaskProgressIsolateEvent(
      taskId: json['taskId'] as String,
      progress: (json['progress'] as num).toDouble(),
    );
  }
}

// 任务完成事件消息
class TaskCompletedIsolateEvent extends IsolateEvent {
  @override
  final String type = "completed";
  final String taskId;
  final dynamic result; // 使用泛型更佳

  TaskCompletedIsolateEvent({required this.taskId, this.result});

  @override
  Map<String, dynamic> serialize() => {
    'type': type,
    'taskId': taskId,
    'result': result,
    'timestamp': timestamp.toIso8601String(),
  };

  factory TaskCompletedIsolateEvent.deserialize(Map<String, dynamic> json) {
    return TaskCompletedIsolateEvent(taskId: json['taskId'] as String, result: json['result']);
  }
}

// 任务出错事件消息
class TaskErrorIsolateEvent extends IsolateEvent {
  @override
  final String type = "error";
  final String taskId;
  final String error;
  final StackTrace stackTrace;

  TaskErrorIsolateEvent({required this.taskId, required this.error, required this.stackTrace});

  @override
  Map<String, dynamic> serialize() => {
    'type': type,
    'taskId': taskId,
    'error': error,
    'stackTrace': stackTrace.toString(),
    'timestamp': timestamp.toIso8601String(),
  };

  factory TaskErrorIsolateEvent.deserialize(Map<String, dynamic> json) {
    return TaskErrorIsolateEvent(
      taskId: json['taskId'] as String,
      error: json['error'] as String,
      stackTrace: StackTrace.fromString(json['stackTrace'] as String),
    );
  }
}

// UI 主线程事件消息
abstract class UiEvent {
  String get type;
  final DateTime timestamp = DateTime.now();

  Map<String, dynamic> serialize();

  static UiEvent? deserialize(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'pause':
        return PauseTaskUiEvent.deserialize(json);
      case 'recover':
        return RecoverTaskUiEvent.deserialize(json);
      case 'cancel':
        return CancelTaskUiEvent.deserialize(json);
      case 'delete':
        return DeleteTaskUiEvent.deserialize(json);
      default:
        return null;
    }
  }
}

// 暂停任务事件消息
class PauseTaskUiEvent extends UiEvent {
  @override
  final String type = "pause";
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
  final String type = "cancel";
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
class RecoverTaskUiEvent extends UiEvent {
  @override
  final String type = "recover";
  final String taskId;

  RecoverTaskUiEvent({required this.taskId});

  @override
  Map<String, dynamic> serialize() => {
    'type': type,
    'taskId': taskId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RecoverTaskUiEvent.deserialize(Map<String, dynamic> json) {
    return RecoverTaskUiEvent(taskId: json['taskId'] as String);
  }
}

// 删除任务事件
class DeleteTaskUiEvent extends UiEvent {
  @override
  final String type = "delete";
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
