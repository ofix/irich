// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/provider_task.dart
// Purpose:     task provider
// Author:      songhuabiao
// Created:     2025-06-30 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/service/task_scheduler.dart';
import 'package:irich/service/tasks/task.dart';

class TaskState {
  List<Task> tasks;
  Task? selectedTask;
  List<TaskRequestLog> selectedTaskLogs;
  TaskState({this.selectedTask, List<Task>? tasks, List<TaskRequestLog>? selectedTaskLogs})
    : tasks = tasks ?? [],
      selectedTaskLogs = selectedTaskLogs ?? [];

  TaskState copyWith({
    List<Task>? tasks,
    Task? selectedTask,
    List<TaskRequestLog>? selectedTaskLogs,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      selectedTask: selectedTask ?? this.selectedTask,
      selectedTaskLogs: selectedTaskLogs ?? this.selectedTaskLogs,
    );
  }
}

final taskSchedulerProvider = FutureProvider<TaskScheduler>((ref) async {
  return await TaskScheduler.getInstance();
});

class TaskNotifer extends StateNotifier<TaskState> {
  TaskScheduler? taskScheduler;
  TaskNotifer() : super(TaskState());

  void initialize() async {
    taskScheduler = await TaskScheduler.getInstance();
    taskScheduler?.addListener(onTick);
    state = TaskState(tasks: taskScheduler?.taskList, selectedTask: taskScheduler?.selectedTask);
  }

  @override
  void dispose() {
    taskScheduler?.removeListener(onTick);
    super.dispose();
  }

  void onTick() {
    state = TaskState(
      tasks: taskScheduler?.taskList,
      selectedTask: taskScheduler?.selectedTask,
      selectedTaskLogs: taskScheduler?.selectTaskLogs() ?? [],
    );
  }

  void addTask(Task task) {
    taskScheduler?.addTask(task);
    state = TaskState(tasks: taskScheduler?.taskList);
  }

  void selectTask(Task task) {
    taskScheduler?.selectTask(task);
    state = state.copyWith(
      selectedTask: taskScheduler?.selectedTask,
      selectedTaskLogs: taskScheduler?.selectTaskLogs(),
    );
  }

  void resumeTask(String taskId) {
    taskScheduler?.resumeTask(taskId);
    state = state.copyWith(
      selectedTask: taskScheduler?.selectedTask,
      tasks: taskScheduler?.taskList,
    );
  }

  void pauseTask(String taskId) {
    taskScheduler?.pauseTask(taskId);
    state = state.copyWith(
      selectedTask: taskScheduler?.selectedTask,
      tasks: taskScheduler?.taskList,
    );
  }
}

final taskProvider = StateNotifierProvider<TaskNotifer, TaskState>((ref) {
  final notifier = TaskNotifer();
  notifier.initialize();
  return notifier;
});
