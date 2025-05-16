// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/task.dart
// Purpose:     task base class
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:irich/service/task_scheduler/task_events.dart';
import 'package:irich/service/task_scheduler/task_sync_share_concept.dart';
import 'package:irich/service/task_scheduler/task_sync_share_industry.dart';
import 'package:irich/service/task_scheduler/task_sync_share_quote.dart';
import 'package:irich/service/task_scheduler/task_sync_share_region.dart';
import 'package:uuid/uuid.dart';

enum TaskPriority implements Comparable<TaskPriority> {
  immediate(4), // 最高优先级(如实时行情)
  high(3), // 高优先级(如板块数据)
  normal(2), // 普通优先级(如历史数据)
  low(1), // 低优先级(后台批量任务)
  unknown(0);

  final int priority;

  const TaskPriority(this.priority);

  @override
  int compareTo(TaskPriority other) {
    return priority.compareTo(other.priority);
  }

  int get val => priority;

  static TaskPriority fromVal(int value) {
    return TaskPriority.values.firstWhere(
      (e) => e.priority == value,
      orElse: () => TaskPriority.unknown,
    );
  }
}

enum TaskStatus {
  pending(1), // 任务等待中
  running(2), // 任务进行中
  paused(3), // 任务暂停
  completed(4), // 任务完成（成功）
  cancelled(5), // 任务取消
  failed(6), // 任务失败
  unknown(0);

  final int status;
  const TaskStatus(this.status);

  bool get isActive => this == running || this == paused;
  bool get canCancel => isActive;
  int get val => status;

  static TaskStatus fromVal(int value) {
    return TaskStatus.values.firstWhere((e) => e.status == value, orElse: () => TaskStatus.unknown);
  }
}

// 爬取任务类型
enum TaskType implements Comparable<TaskType> {
  syncShareQuote(1), // 同步最新行情数据
  syncShareBk(2), // 同步最新板块数据
  syncShareRegion(3), // 同步最新全量股票地域数据
  syncShareRegionPartial(4), // 增量同步最新股票地域数据
  syncShareIndustry(5), // 同步最新全量股票行业数据
  syncShareIndustryPartial(6), // 增量同步最新股票行业数据
  syncShareConcept(7), // 同步最新全量股票概念数据
  syncShareConceptPartial(8), // 增量同步最新股票概念数据
  syncShareDailyKline(9), // 同步最新全量股票前复权日K线数据
  syncShareDailyKlinePartial(10), // 增量同步最新股票前复权日K线数据
  syncShareBasicInfo(11), // 同步全量股票基本信息
  syncShareBasicInfoPartial(12), // 增量同步股票基本信息
  syncIndexDailyKline(13), // 同步最新全量指数前复权日K线数据
  syncIndexDailyKlinePartial(14), // 增量同步最新指数前复权日K线数据
  syncIndexMinuteKline(15), // 同步最新全量指数分时图数据
  // 耗时任务
  smartShareAnalysis(100), // 股票智选
  unknown(255);

  final int type;
  const TaskType(this.type);

  @override
  int compareTo(TaskType other) {
    return type.compareTo(other.type);
  }

  int get val => type;

  static TaskType fromVal(int value) {
    return TaskType.values.firstWhere((e) => e.type == value, orElse: () => TaskType.unknown);
  }
}

abstract class Task {
  TaskType get type; // 任务类型
  dynamic params; // 任务参数
  String taskId;
  TaskPriority priority; // 任务优先级
  late DateTime submitTime; // 任务提交到调度中心的时间
  DateTime? startTime; // 任务开始时间
  DateTime? endTime; // 任务结束时间
  int? timeConsumeInSeconds; // 任务耗时(单位：秒)
  TaskStatus status; // 任务状态
  SendPort? mainThread; // 向主线程发送消息
  int threadId; // 线程ID
  double progress; // 任务进度
  /// 基类构造函数 - 子类必须调用
  Task({
    required this.params,
    this.priority = TaskPriority.normal,
    DateTime? submitTime, // 改为可选参数
    this.status = TaskStatus.pending,
  }) : taskId = const Uuid().v4(),
       submitTime = submitTime ?? DateTime.now(),
       threadId = 0,
       progress = 0;

  Map<String, dynamic> serialize() => {
    "type": type.val,
    "params": jsonEncode(params),
    "taskId": taskId,
    "priority": priority.val,
    "status": status.val,
    "progress": progress,
    "startTime": startTime?.toIso8601String(),
  };

  static Task deserialize(Map<String, dynamic> json) {
    TaskType type = TaskType.fromVal(json['type'] as int);
    // 根据类型创建具体任务实例
    switch (type) {
      case TaskType.syncShareQuote:
        return TaskSyncShareQuote.deserialize(json);
      case TaskType.syncShareIndustry:
        return TaskSyncShareIndustry.deserialize(json);
      case TaskType.syncShareRegion:
        return TaskSyncShareRegion.deserialize(json);
      case TaskType.syncShareConcept:
        return TaskSyncShareConcept.deserialize(json);
      default:
        throw UnsupportedError('Unknown task type: ${json['type']}');
    }
  }

  Future<dynamic> run(); // 任务主体函数
  void onProgressUi(Map<String, dynamic> params, String providerName) {} // 任务进度回调函数，UI层
  void onErrorUi(Object error, StackTrace stackTrace) {} // 任务执行失败回调函数
  Future<void> onCompleted() async {} // 任务完成后在UI线程继续需要完成的事情
  void onCancelledIsolate(String taskId) {} // 任务取消回调函数
  void onPausedIsolate() {} // 任务暂停回调函数
  void onResumedIsolate(String taskId) {} // 任务恢复回调，子线程中完成
  void onStartedUi() {} // 任务已开始回调函数，UI层
  void onCompletedUi() {} // 任务完成的回调
  void notifyUi(IsolateEvent isolateEvent) {
    final message = isolateEvent.serialize();
    mainThread?.send(message);
  }
}

class TaskSyncShareRegionPartial<R> extends Task {
  @override
  TaskType type = TaskType.syncShareRegionPartial;
  TaskSyncShareRegionPartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<dynamic> run() {
    // 实现增量同步最新股票地域数据
    throw UnimplementedError("TaskSyncShareRegionPartial must implement run()");
  }
}

class TaskSyncShareIndustryPartial<R> extends Task {
  @override
  TaskType type = TaskType.syncShareIndustryPartial;
  TaskSyncShareIndustryPartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<dynamic> run() {
    // 实现增量同步最新股票行业数据
    throw UnimplementedError("TaskSyncShareIndustryPartial must implement run()");
  }
}

class TaskSyncShareConceptPartial<R> extends Task {
  @override
  TaskType type = TaskType.syncShareConceptPartial;
  TaskSyncShareConceptPartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<dynamic> run() {
    // 实现增量同步最新股票概念数据
    throw UnimplementedError("TaskSyncShareConceptPartial must implement run()");
  }
}

class TaskSyncShareDailyKline<R> extends Task {
  @override
  TaskType type = TaskType.syncShareDailyKline;
  TaskSyncShareDailyKline({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<dynamic> run() {
    // 实现同步最新全量股票前复权日K线数据
    throw UnimplementedError("TaskSyncShareDailyKline must implement run()");
  }
}

class TaskSyncShareDailyKlinePartial<R> extends Task {
  @override
  TaskType type = TaskType.syncShareDailyKlinePartial;
  TaskSyncShareDailyKlinePartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<dynamic> run() {
    // 实现增量同步最新股票前复权日K线数据
    throw UnimplementedError("TaskSyncShareDailyKlinePartial must implement run()");
  }
}

class TaskSyncShareBasicInfo<R> extends Task {
  @override
  TaskType type = TaskType.syncShareBasicInfo;
  TaskSyncShareBasicInfo({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<dynamic> run() {
    // 实现同步全量股票基本信息
    throw UnimplementedError("TaskSyncShareBasicInfo must implement run()");
  }
}

class TaskSyncShareBasicInfoPartial<R> extends Task {
  @override
  TaskType type = TaskType.syncShareBasicInfoPartial;
  TaskSyncShareBasicInfoPartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<dynamic> run() {
    // 实现增量同步股票基本信息
    throw UnimplementedError("TaskSyncShareBasicInfoPartial must implement run()");
  }
}

class TaskSyncIndexDailyKline<R> extends Task {
  @override
  TaskType type = TaskType.syncIndexDailyKline;
  TaskSyncIndexDailyKline({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<dynamic> run() {
    // 实现同步最新全量指数前复权日K线数据
    throw UnimplementedError("TaskSyncIndexDailyKline must implement run()");
  }
}

class TaskSyncIndexDailyKlinePartial<R> extends Task {
  @override
  TaskType type = TaskType.syncIndexDailyKlinePartial;
  TaskSyncIndexDailyKlinePartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<dynamic> run() {
    // 实现增量同步最新指数前复权日K线数据
    throw UnimplementedError("TaskSyncIndexDailyKlinePartial must implement run()");
  }
}

class TaskSyncIndexMinuteKline<R> extends Task {
  @override
  TaskType type = TaskType.syncIndexMinuteKline;
  TaskSyncIndexMinuteKline({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<dynamic> run() {
    // 实现同步最新全量指数分时图数据
    throw UnimplementedError("TaskSyncIndexMinuteKline must implement run()");
  }
}

class TaskSmartShareAnalysis<R> extends Task {
  @override
  TaskType type = TaskType.smartShareAnalysis;
  TaskSmartShareAnalysis({
    required super.params,
    super.priority = TaskPriority.high,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<dynamic> run() {
    // 实现股票智选分析
    throw UnimplementedError("TaskSmartShareAnalysis must implement run()");
  }
}
