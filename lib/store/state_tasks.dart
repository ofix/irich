// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/state_tasks.dart
// Purpose:     tasks state
// Author:      songhuabiao
// Created:     2025-05-18 22:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/service/request_log.dart';
import 'package:irich/service/tasks/task.dart';
import 'package:irich/service/task_scheduler.dart';

class StateTaskList extends StateNotifier<List<Task>> {
  final TaskScheduler? _scheduler;

  StateTaskList(this._scheduler) : super(_scheduler?.taskList ?? []) {
    _scheduler?.addListener(_updateState);
  }

  Map<String, dynamic> get stats => _scheduler?.stats ?? {};

  void _updateState() {
    if (_scheduler != null) {
      state = [..._scheduler!.taskList];
    }
  }

  void selectTask(Task task) {
    _scheduler?.selectTask(task);
  }

  @override
  void dispose() {
    _scheduler?.removeListener(_updateState);
    super.dispose();
  }
}

// 定义全局 TaskScheduler 单例 Provider
final taskSchedulerProvider = FutureProvider<TaskScheduler>((ref) async {
  return await TaskScheduler.getInstance();
});

// 定义 StoreTaskList 的 StateNotifierProvider
final stateTaskListProvider = StateNotifierProvider<StateTaskList, List<Task>>((ref) {
  final asyncScheduler = ref.watch(taskSchedulerProvider);

  return asyncScheduler.when(
    loading: () => StateTaskList(null),
    error: (err, stack) => StateTaskList(null),
    data: (scheduler) => StateTaskList(scheduler),
  );
});

// 定义选中任务的 Provider
final selectedTaskProvider = Provider<Task?>((ref) {
  return ref.watch(
    taskSchedulerProvider.select((asyncScheduler) => asyncScheduler.valueOrNull?.selectedTask),
  );
});

// 定义统计信息的 Provider
final taskStatsProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(stateTaskListProvider.notifier).stats;
});

// 定义选中的日志列表 Provider
final selectedTaskLogsProvider = Provider<List<RequestLog>>((ref) {
  final asyncScheduler = ref.watch(taskSchedulerProvider);
  final selectedTask = ref.watch(selectedTaskProvider);

  return asyncScheduler.when(
    loading: () => [],
    error: (_, __) => [],
    data: (scheduler) {
      return selectedTask != null ? scheduler.selectTaskLogs() : [];
    },
  );
});
