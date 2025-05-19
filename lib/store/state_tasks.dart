// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/state_tasks.dart
// Purpose:     tasks state
// Author:      songhuabiao
// Created:     2025-05-18 22:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/service/task_scheduler/task.dart';
import 'package:irich/service/task_scheduler/task_scheduler.dart';

class StateTaskList extends StateNotifier<List<Task>> {
  final TaskScheduler _scheduler;

  StateTaskList(this._scheduler) : super(_scheduler.taskList) {
    _scheduler.addListener(_updateState);
  }

  Map<String, dynamic> get stats => _scheduler.stats;

  void _updateState() {
    state = [..._scheduler.taskList];
  }

  void selectTask(Task task) {
    _scheduler.selectTask(task);
  }

  @override
  void dispose() {
    _scheduler.removeListener(_updateState);
    super.dispose();
  }
}

// 定义全局 TaskScheduler 单例 Provider
final taskSchedulerProvider = Provider<TaskScheduler>((ref) {
  return TaskScheduler(); // 创建单例实例
});

// 定义 StoreTaskList 的 StateNotifierProvider
final stateTaskListProvider = StateNotifierProvider<StateTaskList, List<Task>>((ref) {
  // 通过 ref.read 获取 TaskScheduler 实例
  final scheduler = ref.read(taskSchedulerProvider);
  return StateTaskList(scheduler); // 创建 StoreTaskList 并传入 scheduler
});

// 定义选中任务的 Provider
final selectedTaskProvider = Provider<Task?>((ref) {
  // 使用 select 监听 TaskScheduler 的 selectedTask 变化
  return ref.watch(taskSchedulerProvider.select((scheduler) => scheduler.selectedTask));
});

// 定义统计信息的 Provider
final statsProvider = Provider<Map<String, dynamic>>((ref) {
  // 从 StoreTaskList 的 notifier 获取统计信息
  return ref.watch(stateTaskListProvider.notifier).stats;
});
