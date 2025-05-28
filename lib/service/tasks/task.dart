// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/tasks/task.dart
// Purpose:     task base class
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:irich/global/config.dart';
import 'package:irich/service/task_events.dart';
import 'package:irich/service/tasks/task_sync_share_concept.dart';
import 'package:irich/service/tasks/task_sync_share_industry.dart';
import 'package:irich/service/tasks/task_sync_share_quote.dart';
import 'package:irich/service/tasks/task_sync_share_region.dart';
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
    switch (value) {
      case 4:
        return TaskPriority.immediate;
      case 3:
        return TaskPriority.high;
      case 2:
        return TaskPriority.normal;
      case 1:
        return TaskPriority.low;
      case 0:
        return TaskPriority.unknown;
      default:
        return TaskPriority.unknown;
    }
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
    switch (value) {
      case 1:
        return TaskStatus.pending;
      case 2:
        return TaskStatus.running;
      case 3:
        return TaskStatus.paused;
      case 4:
        return TaskStatus.completed;
      case 5:
        return TaskStatus.cancelled;
      case 6:
        return TaskStatus.failed;
      case 7:
        return TaskStatus.exit;
      case 0:
        return TaskStatus.unknown;
      default:
        throw ArgumentError('Invalid task status value: $value');
    }
  }

  String get name {
    const names = {1: '等待中', 2: '运行中', 3: '已暂停', 4: '已完成', 5: '已取消', 6: '失败', 7: '已退出', 0: '未知状态'};
    return names[status] ?? '未知状态';
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
  //
  taskGroup(200), // 任务组
  unknown(255);

  final int type;
  const TaskType(this.type);

  @override
  int compareTo(TaskType other) {
    return type.compareTo(other.type);
  }

  int get val => type;

  static TaskType fromVal(int value) {
    switch (value) {
      // 行情数据
      case 1:
        return syncShareQuote;
      case 2:
        return syncShareBk;
      case 3:
        return syncShareRegion;
      case 4:
        return syncShareRegionPartial;
      case 5:
        return syncShareIndustry;
      case 6:
        return syncShareIndustryPartial;
      case 7:
        return syncShareConcept;
      case 8:
        return syncShareConceptPartial;
      case 9:
        return syncShareDailyKline;
      case 10:
        return syncShareDailyKlinePartial;

      // 基础信息
      case 11:
        return syncShareBasicInfo;
      case 12:
        return syncShareBasicInfoPartial;
      case 13:
        return syncIndexDailyKline;
      case 14:
        return syncIndexDailyKlinePartial;

      // 实时数据
      case 15:
        return syncIndexMinuteKline;

      // 分析任务
      case 100:
        return smartShareAnalysis;
      case 200:
        return taskGroup;

      // 未知类型
      case 255:
        return unknown;
      default:
        return unknown;
    }
  }

  String get name {
    const names = {
      1: '行情数据同步',
      2: '板块数据同步',
      3: '股票地域(全量)',
      4: '股票地域(增量)',
      5: '股票行业(全量)',
      6: '股票行业(增量)',
      7: '股票概念(全量)',
      8: '股票概念(增量)',
      9: '股票日K线(全量)',
      10: '股票日K线(增量)',
      11: '股票基本信息(全量)',
      12: '股票基本信息(增量)',
      13: '指数日K线(全量)',
      14: '指数日K线(增量)',
      15: '指数分时图(全量)',
      100: '智能选股分析',
      200: '任务组',
      255: '未知类型',
    };
    return names[type] ?? '未知任务类型';
  }
}

abstract class Task<T> implements Comparable<Task<T>> {
  TaskType get type; // 任务类型
  dynamic params; // 任务参数
  String taskId;
  String parentTaskId = ""; // 父任务ID，默认为空字符串
  TaskPriority priority; // 任务优先级
  DateTime submitTime; // 任务提交到调度中心的时间
  DateTime? startTime; // 任务开始时间
  DateTime? endTime; // 任务结束时间
  int? timeConsumeInSeconds; // 任务耗时(单位：秒)
  TaskStatus status; // 任务状态
  double progress; // 任务进度
  SendPort? mainThread; // 向主线程发送消息
  int threadId; // 线程ID
  Completer<T>? completer; // 处理
  bool isProcessing; // 正在处理中，暂停任务或者恢复任务需要等待子线程完成，期间不允许用户进行其他操作
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
       progress = 0,
       isProcessing = false;

  // 状态计算属性
  Duration get waitingDuration =>
      startTime != null ? startTime!.difference(submitTime) : DateTime.now().difference(submitTime);

  Duration? get executionDuration =>
      endTime != null && startTime != null ? endTime!.difference(startTime!) : null;

  @override
  int compareTo(Task<T> other) => other.priority.compareTo(priority);

  Map<String, dynamic> serialize() => {
    "Type": type.val,
    "Priority": priority.val,
    "TaskId": taskId,
    "ParentTaskId": parentTaskId,
    "ThreadId": threadId,
    "Status": status.val,
    "Params": jsonEncode(params),
    "SubmitTime": submitTime.toIso8601String(),
    "StartTime": startTime?.toIso8601String(),
    "Progress": progress,
  };

  // 命名子类构造函数，供子类复用
  Task.build(Map<String, dynamic> json)
    : priority = TaskPriority.fromVal(json['Priority'] as int),
      taskId = json['TaskId'] as String,
      parentTaskId = json['ParentTaskId'] as String,
      status = TaskStatus.fromVal(json['Status'] as int),
      params = jsonDecode(json['Params']),
      submitTime = DateTime.parse(json['SubmitTime']),
      startTime = json['StartTime'] != null ? DateTime.parse(json['StartTime']) : null,
      progress = json['Progress'] as double,
      threadId = json['ThreadId'] as int,
      isProcessing = false;

  static dynamic deserialize(Map<String, dynamic> json) {
    TaskType type = TaskType.fromVal(json['Type'] as int);
    // 根据类型创建具体任务实例
    switch (type) {
      case TaskType.syncShareQuote:
        return TaskSyncShareQuote.build(json);
      case TaskType.syncShareIndustry:
        return TaskSyncShareIndustry.build(json);
      case TaskType.syncShareRegion:
        return TaskSyncShareRegion.build(json);
      case TaskType.syncShareConcept:
        return TaskSyncShareConcept.build(json);
      default:
        throw UnsupportedError('Unknown task type: ${json['type']}');
    }
  }

  Future<T> run(); // 任务主体函数

  bool get hasParentTask => parentTaskId.isNotEmpty; // 是否有父任务

  void onErrorUi(TaskErrorEvent event) {} // 任务执行失败回调函数
  void onCancelledIsolate() {} // 任务取消回调函数
  Future<void> onPausedIsolate() async {} // 任务暂停回调函数
  static Future<Task> onResumedIsolate(String taskId, int threadId) async {
    String taskPath = await Config.pathTask;
    String pausedFilePath = p.join(taskPath, taskId, ".json");
    final data = await FileTool.loadFile(pausedFilePath);
    final json = jsonDecode(data);
    final task = Task.deserialize(json);
    task.params = json['Params']; // 用参数覆盖原有的参数列表，继续未完成的请求
    task.responses = json['Responses'];
    task.status = TaskStatus.running;
    task.startTime = json['StartTime'] != null ? DateTime.parse(json['StartTime']) : DateTime.now();
    task.submitTime = DateTime.fromMillisecondsSinceEpoch(json['SubmitTime']);
    final resumeEvent = TaskResumedEvent(threadId: threadId, taskId: taskId);
    task.notifyUi(resumeEvent);
    return task;
  } // 任务恢复回调，子线程中完成

  void onStartedUi(TaskStartedEvent event) {
    debugPrint("任务 ${event.taskId} 已启动！");
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
  TaskSyncShareRegionPartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Map<String, dynamic> serialize() => {};

  @override
  Future<T> run() {
    // 实现增量同步最新股票地域数据
    throw UnimplementedError("TaskSyncShareRegionPartial must implement run()");
  }
}

class TaskSyncShareIndustryPartial<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncShareIndustryPartial;
  TaskSyncShareIndustryPartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Map<String, dynamic> serialize() => {};

  @override
  Future<T> run() {
    // 实现增量同步最新股票行业数据
    throw UnimplementedError("TaskSyncShareIndustryPartial must implement run()");
  }
}

class TaskSyncShareConceptPartial<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncShareConceptPartial;
  TaskSyncShareConceptPartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Map<String, dynamic> serialize() => {};

  @override
  Future<T> run() {
    // 实现增量同步最新股票概念数据
    throw UnimplementedError("TaskSyncShareConceptPartial must implement run()");
  }
}

class TaskSyncShareDailyKline<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncShareDailyKline;
  TaskSyncShareDailyKline({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Map<String, dynamic> serialize() => {};

  @override
  Future<T> run() {
    // 实现同步最新全量股票前复权日K线数据
    throw UnimplementedError("TaskSyncShareDailyKline must implement run()");
  }
}

class TaskSyncShareDailyKlinePartial<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncShareDailyKlinePartial;
  TaskSyncShareDailyKlinePartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Map<String, dynamic> serialize() => {};

  @override
  Future<T> run() {
    // 实现增量同步最新股票前复权日K线数据
    throw UnimplementedError("TaskSyncShareDailyKlinePartial must implement run()");
  }
}

class TaskSyncShareBasicInfo<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncShareBasicInfo;
  TaskSyncShareBasicInfo({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Map<String, dynamic> serialize() => {};

  @override
  Future<T> run() {
    // 实现同步全量股票基本信息
    throw UnimplementedError("TaskSyncShareBasicInfo must implement run()");
  }
}

class TaskSyncShareBasicInfoPartial<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncShareBasicInfoPartial;
  TaskSyncShareBasicInfoPartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Map<String, dynamic> serialize() => {};

  @override
  Future<T> run() {
    // 实现增量同步股票基本信息
    throw UnimplementedError("TaskSyncShareBasicInfoPartial must implement run()");
  }
}

class TaskSyncIndexDailyKline<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncIndexDailyKline;
  TaskSyncIndexDailyKline({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Map<String, dynamic> serialize() => {};

  @override
  Future<T> run() {
    // 实现同步最新全量指数前复权日K线数据
    throw UnimplementedError("TaskSyncIndexDailyKline must implement run()");
  }
}

class TaskSyncIndexDailyKlinePartial<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncIndexDailyKlinePartial;
  TaskSyncIndexDailyKlinePartial({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Map<String, dynamic> serialize() => {};

  @override
  Future<T> run() {
    // 实现增量同步最新指数前复权日K线数据
    throw UnimplementedError("TaskSyncIndexDailyKlinePartial must implement run()");
  }
}

class TaskSyncIndexMinuteKline<T> extends Task<T> {
  @override
  TaskType type = TaskType.syncIndexMinuteKline;
  TaskSyncIndexMinuteKline({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Map<String, dynamic> serialize() => {};

  @override
  Future<T> run() {
    // 实现同步最新全量指数分时图数据
    throw UnimplementedError("TaskSyncIndexMinuteKline must implement run()");
  }
}

class TaskSmartShareAnalysis<T> extends Task<T> {
  @override
  TaskType type = TaskType.smartShareAnalysis;
  TaskSmartShareAnalysis({
    required super.params,
    super.priority = TaskPriority.high,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  @override
  Map<String, dynamic> serialize() => {};

  @override
  Future<T> run() {
    // 实现股票智选分析
    throw UnimplementedError("TaskSmartShareAnalysis must implement run()");
  }
}
