// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/tasks/task_sync_share_region.dart
// Purpose:     synchronize share region task
// Author:      songhuabiao
// Created:     2025-05-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/service/task_events.dart';
import 'package:irich/service/task_scheduler.dart';
import 'package:irich/service/tasks/task.dart';

enum SubTaskCategory {
  parallel(1), // 最高优先级(如实时行情)
  serial(2); // 高优先级(如板块数据)

  final int category;
  const SubTaskCategory(this.category);

  int get val => category;
  static SubTaskCategory fromVal(int value) {
    switch (value) {
      case 1:
        return SubTaskCategory.parallel;
      case 2:
        return SubTaskCategory.serial;
      default:
        return SubTaskCategory.serial; // 默认返回串行任务
    }
  }
}

class TaskGroup extends Task<void> {
  @override
  TaskType type = TaskType.taskGroup;
  final List<List<Task>> subTasks; // 子任务列表
  late TaskScheduler taskScheduler; // 任务调度器
  int totalBarriers = 0; // 总的屏障数
  int currentBarrier = 0; // 当前屏障数
  int subTaskSize = 0; // 子任务集合的大小
  SubTaskCategory lastSubTaskCategory = SubTaskCategory.serial; // 上次添加的子任务类别;
  Function()? _onComplete; // 完成回调函数
  Function()? _onError; // 错误处理函数
  TaskGroup({
    super.params,
    super.priority,
    super.submitTime,
    super.status,
    this.subTasks = const [],
  });

  /// 在子线程中运行
  @override
  Future<void> run() async {
    totalBarriers = subTasks.length; // 初始化总屏障数
    if (totalBarriers == 0) {
      return; // 没有子任务，直接返回
    }
    status = TaskStatus.running; // 设置任务状态为运行中
    taskScheduler = await TaskScheduler.getInstance();
    List<Task> currentTasks = subTasks[currentBarrier];
    for (var task in currentTasks) {
      taskScheduler.addTask(task);
    }
  }

  // 任务组完成回调函数
  void onComplete(Function() callback) {
    _onComplete = callback;
  }

  // 任务组出错处理函数
  void onError(Function() callback) {
    _onError = callback;
  }

  Future<void> dispatchTasks() async {
    if (!isCurrentBarrierCompleted()) {
      return;
    }
    currentBarrier += 1; // 增加当前屏障数
    if (currentBarrier >= totalBarriers) {
      status = TaskStatus.completed; // 所有屏障已完成
      _onComplete?.call(); // 调用完成回调
      return;
    }
    taskScheduler = await TaskScheduler.getInstance();
    List<Task> currentTasks = subTasks[currentBarrier];
    for (var task in currentTasks) {
      taskScheduler.addTask(task);
    }
  }

  /// 检查当前屏障是否已完成
  bool isCurrentBarrierCompleted() {
    // 检查当前屏障的所有任务是否都已完成
    for (var task in subTasks[currentBarrier]) {
      if (task.status != TaskStatus.completed && task.status != TaskStatus.failed) {
        return false; // 有任务未完成
      }
    }
    return true; // 当前屏障已完成
  }

  // 设置子任务集合的父任务ID
  void addSubTaskParentIds(List<Task> tasks) {
    for (var task in tasks) {
      task.parentTaskId = taskId; // 设置父任务ID
    }
  }

  // 设置子任务的父任务ID
  void addSubTaskParentId(Task task) {
    task.parentTaskId = taskId; // 设置父任务ID
  }

  // 添加并行任务集合
  void addParallelSubTaskSet(List<Task> tasks) {
    addSubTaskParentIds(tasks);
    if (lastSubTaskCategory == SubTaskCategory.serial) {
      // 如果上次添加的是串行任务，则增加一个屏障
      totalBarriers += 1;
      subTasks.add(tasks);
    } else {
      subTasks.last.addAll(tasks); // 添加到最后一层的并行任务中
    }
    subTaskSize += tasks.length; // 更新子任务集合的大小
    lastSubTaskCategory = SubTaskCategory.parallel;
  }

  void appParallelSubTask(Task task) {
    addSubTaskParentId(task);
    if (lastSubTaskCategory == SubTaskCategory.serial) {
      subTasks.add([task]); // 设置为并行任务,每一层可以有多个任务
      totalBarriers += 1; // 增加屏障数
    } else {
      subTasks.last.add(task); // 添加到最后一层的并行任务中
    }
    subTaskSize += 1; // 更新子任务集合的大小
    lastSubTaskCategory = SubTaskCategory.parallel;
  }

  void addSerialSubTaskSet(List<Task> tasks) {
    addSubTaskParentIds(tasks);
    for (var task in tasks) {
      subTasks.add([task]); // 设置为串行任务,每一层只有一个任务
      totalBarriers += 1; // 增加屏障数
    }
    subTaskSize += tasks.length; // 更新子任务集合的大小
    lastSubTaskCategory = SubTaskCategory.serial;
  }

  void addSerialSubTask(Task task) {
    addSubTaskParentId(task);
    subTasks.add([task]);
    totalBarriers += 1; // 增加屏障数
    subTaskSize += 1; // 更新子任务集合的大小
    lastSubTaskCategory = SubTaskCategory.serial;
  }

  @override
  void onProgressUi(TaskProgressEvent event) {
    int finishedTasks = 0; // 已完成的子任务数
    double totalProgress = 0.0; // 总进度
    for (int i = 0; i < currentBarrier; i++) {
      finishedTasks += subTasks[i].length;
    }

    double oneTaskProgress = 1.0 / subTaskSize;

    for (final task in subTasks[currentBarrier]) {
      if (task.status == TaskStatus.completed || task.status == TaskStatus.failed) {
        finishedTasks += 1; // 当前屏障的任务已完成
      } else if (task.status == TaskStatus.running) {
        totalProgress += oneTaskProgress * task.progress; // 计算当前任务的进度
      }
    }
    totalProgress += finishedTasks * oneTaskProgress; // 累加已完成任务的进度
    progress = totalProgress; // 更新总进度
    final progressEvent = TaskProgressEvent(
      threadId: threadId,
      taskId: taskId,
      progress: progress,
      requestLog: event.requestLog,
    );
    notifyUi(progressEvent); // 通知UI更新进度
  }

  @override
  void onErrorUi(TaskErrorEvent event) {
    status = TaskStatus.failed; // 设置任务状态为失败
    _onError?.call(); // 调用错误处理函数
  }

  @override
  Map<String, dynamic> serialize() => {
    ...super.serialize(),
    'SubTasks':
        subTasks.map((taskList) => taskList.map((task) => task.serialize()).toList()).toList(),
  };

  // 命名构造函数
  TaskGroup.build(super.json)
    : subTasks =
          json['SubTasks']
              .map<List<Task>>(
                (taskList) => taskList.map<Task>((task) => Task.deserialize(task)).toList(),
              )
              .toList(),
      super.build();

  @override
  void onCancelledIsolate() {}

  @override
  Future<void> onPausedIsolate() async {}
}
