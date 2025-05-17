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

import 'package:irich/global/config.dart';
import 'package:irich/service/task_scheduler/task_events.dart';
import 'package:irich/service/task_scheduler/task_sync_share_concept.dart';
import 'package:irich/service/task_scheduler/task_sync_share_industry.dart';
import 'package:irich/service/task_scheduler/task_sync_share_quote.dart';
import 'package:irich/service/task_scheduler/task_sync_share_region.dart';
import 'package:irich/utils/file_tool.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

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
  exit(7), // 子线程退出
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

abstract class Task<T> implements Comparable<Task<T>> {
  TaskType get type; // 任务类型
  bool get canPaused; // 是否可暂停
  bool get canCancelled; // 是否可取消
  dynamic params; // 任务参数
  String taskId;
  TaskPriority priority; // 任务优先级
  final DateTime submitTime; // 任务提交到调度中心的时间
  DateTime? startTime; // 任务开始时间
  DateTime? endTime; // 任务结束时间
  int? timeConsumeInSeconds; // 任务耗时(单位：秒)
  TaskStatus status; // 任务状态
  SendPort? mainThread; // 向主线程发送消息
  int threadId; // 线程ID
  double progress; // 任务进度
  Completer<T>? completer;
  List<Map<String, dynamic>>? responses;

  /// 基类构造函数 - 子类必须调用
  Task({
    required this.params,
    this.priority = TaskPriority.normal,
    this.status = TaskStatus.pending,
    DateTime? submitTime, // 改为可选参数
  }) : taskId = const Uuid().v4(),
       submitTime = submitTime ?? DateTime.now(),
       threadId = 0,
       progress = 0;

  // 状态计算属性
  Duration get waitingDuration =>
      startTime != null ? startTime!.difference(submitTime) : DateTime.now().difference(submitTime);

  Duration? get executionDuration =>
      endTime != null && startTime != null ? endTime!.difference(startTime!) : null;

  @override
  int compareTo(Task<T> other) => other.priority.compareTo(priority);

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

  Future<T> run(); // 任务主体函数

  void onErrorUi(TaskErrorEvent event) {} // 任务执行失败回调函数
  void onCancelledIsolate() {} // 任务取消回调函数
  Future<void> onPausedIsolate() async {} // 任务暂停回调函数
  static Future<Task> onResumedIsolate(String taskId, int threadId) async {
    String taskPath = await Config.pathTask;
    String pausedFilePath = p.join(taskPath, taskId, ".json");
    final data = await FileTool.loadFile(pausedFilePath);
    final json = jsonDecode(data);
    final task = Task.deserialize(json);
    task.params = json['params']; // 用参数覆盖原有的参数列表，继续未完成的请求
    task.responses = json['responses'];
    task.status = TaskStatus.running;
    final resumeEvent = TaskResumedEvent(threadId: threadId, taskId: taskId);
    task.notifyUi(resumeEvent);
    return task;
  } // 任务恢复回调，子线程中完成

  void onStartedUi(TaskStartedEvent event) {
    status = TaskStatus.running;
    startTime = event.timestamp;
  } // 任务已开始回调函数，UI层

  void onProgressUi(TaskProgressEvent event) {
    progress = event.progress;
  } // 任务进度回调函数，UI层

  void onCompletedUi(TaskCompletedEvent event, dynamic result) {
    status = TaskStatus.completed;
    endTime = event.timestamp;
  } // 任务完成的回调

  void notifyUi(IsolateEvent isolateEvent) {
    final message = isolateEvent.serialize();
    mainThread?.send(message);
  }
}

class TaskSyncShareRegionPartial<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncShareRegionPartial;
  @override
  bool canPaused = true;
  @override
  bool canCancelled = true;
  TaskSyncShareRegionPartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<T> run() {
    // 实现增量同步最新股票地域数据
    throw UnimplementedError("TaskSyncShareRegionPartial must implement run()");
  }
}

class TaskSyncShareIndustryPartial<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncShareIndustryPartial;
  @override
  bool canPaused = true;
  @override
  bool canCancelled = true;
  TaskSyncShareIndustryPartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<T> run() {
    // 实现增量同步最新股票行业数据
    throw UnimplementedError("TaskSyncShareIndustryPartial must implement run()");
  }
}

class TaskSyncShareConceptPartial<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncShareConceptPartial;
  @override
  bool canPaused = true;
  @override
  bool canCancelled = true;
  TaskSyncShareConceptPartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<T> run() {
    // 实现增量同步最新股票概念数据
    throw UnimplementedError("TaskSyncShareConceptPartial must implement run()");
  }
}

class TaskSyncShareDailyKline<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncShareDailyKline;
  @override
  bool canPaused = true;
  @override
  bool canCancelled = true;
  TaskSyncShareDailyKline({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<T> run() {
    // 实现同步最新全量股票前复权日K线数据
    throw UnimplementedError("TaskSyncShareDailyKline must implement run()");
  }
}

class TaskSyncShareDailyKlinePartial<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncShareDailyKlinePartial;
  @override
  bool canPaused = true;
  @override
  bool canCancelled = true;
  TaskSyncShareDailyKlinePartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<T> run() {
    // 实现增量同步最新股票前复权日K线数据
    throw UnimplementedError("TaskSyncShareDailyKlinePartial must implement run()");
  }
}

class TaskSyncShareBasicInfo<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncShareBasicInfo;
  @override
  bool canPaused = true;
  @override
  bool canCancelled = true;
  TaskSyncShareBasicInfo({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<T> run() {
    // 实现同步全量股票基本信息
    throw UnimplementedError("TaskSyncShareBasicInfo must implement run()");
  }
}

class TaskSyncShareBasicInfoPartial<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncShareBasicInfoPartial;
  @override
  bool canPaused = true;
  @override
  bool canCancelled = true;
  TaskSyncShareBasicInfoPartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<T> run() {
    // 实现增量同步股票基本信息
    throw UnimplementedError("TaskSyncShareBasicInfoPartial must implement run()");
  }
}

class TaskSyncIndexDailyKline<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncIndexDailyKline;
  @override
  bool canPaused = true;
  @override
  bool canCancelled = true;
  TaskSyncIndexDailyKline({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<T> run() {
    // 实现同步最新全量指数前复权日K线数据
    throw UnimplementedError("TaskSyncIndexDailyKline must implement run()");
  }
}

class TaskSyncIndexDailyKlinePartial<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncIndexDailyKlinePartial;
  @override
  bool canPaused = true;
  @override
  bool canCancelled = true;
  TaskSyncIndexDailyKlinePartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<T> run() {
    // 实现增量同步最新指数前复权日K线数据
    throw UnimplementedError("TaskSyncIndexDailyKlinePartial must implement run()");
  }
}

class TaskSyncIndexMinuteKline<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncIndexMinuteKline;
  @override
  bool canPaused = true;
  @override
  bool canCancelled = true;
  TaskSyncIndexMinuteKline({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<T> run() {
    // 实现同步最新全量指数分时图数据
    throw UnimplementedError("TaskSyncIndexMinuteKline must implement run()");
  }
}

class TaskSmartShareAnalysis<T> extends Task<T> {
  @override
  TaskType type = TaskType.smartShareAnalysis;
  @override
  bool canPaused = true;
  @override
  bool canCancelled = true;
  TaskSmartShareAnalysis({
    required super.params,
    super.priority = TaskPriority.high,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Future<T> run() {
    // 实现股票智选分析
    throw UnimplementedError("TaskSmartShareAnalysis must implement run()");
  }
}
