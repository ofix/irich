// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/task_event.dart
// Purpose:     isolate communicate message
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

// 任务子线程事件
import 'package:irich/service/task_scheduler/task.dart';

sealed class IsolateEvent {}

// 任务进度事件消息
class TaskProgressIsolateEvent extends IsolateEvent {
  final String taskId;
  final double progress;
  final dynamic data;

  TaskProgressIsolateEvent({required this.taskId, required this.progress, this.data});
}

// 任务结果事件消息
class TaskResultIsolateEvent<T> extends IsolateEvent {
  final String taskId;
  final T result;

  TaskResultIsolateEvent({required this.taskId, required this.result});
}

// 任务支持出错事件消息
class TaskErrorIsolateEvent extends IsolateEvent {
  final String taskId;
  final dynamic error;
  final StackTrace stackTrace;

  TaskErrorIsolateEvent({required this.taskId, required this.error, required this.stackTrace});
}

// UI 主线程事件消息
sealed class UiEvent {}

// 新增任务事件消息
class NewTaskUiEvent extends UiEvent {
  final Task task;
  NewTaskUiEvent({required this.task});
}

// 暂停任务事件消息
class PauseTaskUiEvent extends UiEvent {
  final String taskId;
  PauseTaskUiEvent({required this.taskId});
}

// 取消任务事件消息
class CancelTaskUiEvent extends UiEvent {
  final String taskId;
  CancelTaskUiEvent({required this.taskId});
}

// 恢复任务事件消息
class RecoverTaskUiEvent extends UiEvent {
  final String taskId;
  RecoverTaskUiEvent({required this.taskId});
}

// 删除任务事件
class DeleteTaskUiEvent extends UiEvent {
  final String taskId;
  DeleteTaskUiEvent({required this.taskId});
}
