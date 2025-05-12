// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/task.dart
// Purpose:     task base class
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';

import 'package:uuid/uuid.dart';

enum TaskPriority implements Comparable<TaskPriority> {
  immediate(4), // 最高优先级(如实时行情)
  high(3), // 高优先级(如板块数据)
  normal(2), // 普通优先级(如历史数据)
  low(1); // 低优先级(后台批量任务)

  final int priority;

  const TaskPriority(this.priority);

  @override
  int compareTo(TaskPriority other) {
    return priority.compareTo(other.priority);
  }
}

enum TaskStatus {
  completed, // 任务完成
  failed, // 任务完全失败
  running, // 任务进行中
  pending, // 任务等待中
  cancelled, // 任务取消了
  paused, // 任务暂停中
}

// 爬取任务类型
enum TaskType {
  syncShareQuote, // 同步最新行情数据
  syncShareRegion, // 同步最新全量股票地域数据
  syncShareRegionPartial, // 增量同步最新股票地域数据
  syncShareIndustry, // 同步最新全量股票行业数据
  syncShareIndustryPartial, // 增量同步最新股票行业数据
  syncShareConcept, // 同步最新全量股票概念数据
  syncShareConceptPartial, // 增量同步最新股票概念数据
  syncShareDailyKline, // 同步最新全量股票前复权日K线数据
  syncShareDailyKlinePartial, // 增量同步最新股票前复权日K线数据
  syncShareBasicInfo, // 同步全量股票基本信息
  syncShareBasicInfoPartial, // 增量同步股票基本信息
  syncIndexDailyKline, // 同步最新全量指数前复权日K线数据
  syncIndexDailyKlinePartial, // 增量同步最新指数前复权日K线数据
  syncIndexMinuteKline, // 同步最新全量指数分时图数据
  // 耗时任务
  smartShareAnalysis, // 股票智选
  unknown,
}

abstract class Task<R> {
  final TaskType type; // 任务类型
  final Map<String, dynamic>? params; // 任务参数
  final String taskId;
  TaskPriority priority; // 任务优先级
  late DateTime submitTime; // 任务提交到调度中心的时间
  DateTime? startTime; // 任务开始时间
  DateTime? endTime; // 任务结束时间
  int? timeConsumeInSeconds; // 任务耗时(单位：秒)
  TaskStatus status; // 任务状态

  /// 基类构造函数 - 子类必须调用
  Task({
    required this.type,
    required this.params,
    String? taskId, // 可选参数，允许自定义taskId
    this.priority = TaskPriority.normal,
    DateTime? submitTime, // 改为可选参数
    this.status = TaskStatus.pending,
  }) : taskId = taskId ?? const Uuid().v4(),
       submitTime = submitTime ?? DateTime.now();

  FutureOr<R> run(); // 任务主体函数
  void onProgress(Map<String, dynamic> params, String providerName) {} // 任务进度回调函数
  void onError(Object error, StackTrace stackTrace) {} // 任务执行失败回调函数
  void onCanceled(String taskId) {} // 任务取消回调函数
  void onResumed(String taskId) {} // 任务恢复回调函数
  void onStarted(String taskId) {} // 任务已开始回调函数
  void onDeleted(String taskId) {} // 任务被删除回调函数
  void onFinally() {}
}

class TaskSyncShareRegionPartial<R> extends Task<R> {
  TaskSyncShareRegionPartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  }) : super(type: TaskType.syncShareRegionPartial);

  @override
  FutureOr<R> run() {
    // 实现增量同步最新股票地域数据
    throw UnimplementedError("TaskSyncShareRegionPartial must implement run()");
  }
}

class TaskSyncShareIndustryPartial<R> extends Task<R> {
  TaskSyncShareIndustryPartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  }) : super(type: TaskType.syncShareIndustryPartial);

  @override
  FutureOr<R> run() {
    // 实现增量同步最新股票行业数据
    throw UnimplementedError("TaskSyncShareIndustryPartial must implement run()");
  }
}

class TaskSyncShareConceptPartial<R> extends Task<R> {
  TaskSyncShareConceptPartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  }) : super(type: TaskType.syncShareConceptPartial);

  @override
  FutureOr<R> run() {
    // 实现增量同步最新股票概念数据
    throw UnimplementedError("TaskSyncShareConceptPartial must implement run()");
  }
}

class TaskSyncShareDailyKline<R> extends Task<R> {
  TaskSyncShareDailyKline({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  }) : super(type: TaskType.syncShareDailyKline);

  @override
  FutureOr<R> run() {
    // 实现同步最新全量股票前复权日K线数据
    throw UnimplementedError("TaskSyncShareDailyKline must implement run()");
  }
}

class TaskSyncShareDailyKlinePartial<R> extends Task<R> {
  TaskSyncShareDailyKlinePartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  }) : super(type: TaskType.syncShareDailyKlinePartial);

  @override
  FutureOr<R> run() {
    // 实现增量同步最新股票前复权日K线数据
    throw UnimplementedError("TaskSyncShareDailyKlinePartial must implement run()");
  }
}

class TaskSyncShareBasicInfo<R> extends Task<R> {
  TaskSyncShareBasicInfo({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  }) : super(type: TaskType.syncShareBasicInfo);

  @override
  FutureOr<R> run() {
    // 实现同步全量股票基本信息
    throw UnimplementedError("TaskSyncShareBasicInfo must implement run()");
  }
}

class TaskSyncShareBasicInfoPartial<R> extends Task<R> {
  TaskSyncShareBasicInfoPartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  }) : super(type: TaskType.syncShareBasicInfoPartial);

  @override
  FutureOr<R> run() {
    // 实现增量同步股票基本信息
    throw UnimplementedError("TaskSyncShareBasicInfoPartial must implement run()");
  }
}

class TaskSyncIndexDailyKline<R> extends Task<R> {
  TaskSyncIndexDailyKline({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  }) : super(type: TaskType.syncIndexDailyKline);

  @override
  FutureOr<R> run() {
    // 实现同步最新全量指数前复权日K线数据
    throw UnimplementedError("TaskSyncIndexDailyKline must implement run()");
  }
}

class TaskSyncIndexDailyKlinePartial<R> extends Task<R> {
  TaskSyncIndexDailyKlinePartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  }) : super(type: TaskType.syncIndexDailyKlinePartial);

  @override
  FutureOr<R> run() {
    // 实现增量同步最新指数前复权日K线数据
    throw UnimplementedError("TaskSyncIndexDailyKlinePartial must implement run()");
  }
}

class TaskSyncIndexMinuteKline<R> extends Task<R> {
  TaskSyncIndexMinuteKline({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  }) : super(type: TaskType.syncIndexMinuteKline);

  @override
  FutureOr<R> run() {
    // 实现同步最新全量指数分时图数据
    throw UnimplementedError("TaskSyncIndexMinuteKline must implement run()");
  }
}

class TaskSmartShareAnalysis<R> extends Task<R> {
  TaskSmartShareAnalysis({
    required super.params,
    super.priority = TaskPriority.high,
    super.submitTime,
    super.status = TaskStatus.pending,
  }) : super(type: TaskType.smartShareAnalysis);

  @override
  FutureOr<R> run() {
    // 实现股票智选分析
    throw UnimplementedError("TaskSmartShareAnalysis must implement run()");
  }
}
