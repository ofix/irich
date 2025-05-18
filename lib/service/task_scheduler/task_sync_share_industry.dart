// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/task_sync_share_industry.dart
// Purpose:     synchronize share industry task
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:irich/global/config.dart';
import 'package:irich/service/api_provider_capabilities.dart';
import 'package:irich/service/task_scheduler/batch_api_task.dart';
import 'package:irich/service/task_scheduler/task.dart';
import 'package:irich/service/task_scheduler/task_events.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/utils/file_tool.dart';

class TaskSyncShareIndustry extends BatchApiTask {
  @override
  TaskType type = TaskType.syncShareIndustry;
  @override
  ProviderApiType apiType = ProviderApiType.industry;
  TaskSyncShareIndustry({
    required super.params,
    super.priority = TaskPriority.normal,
    super.submitTime,
    super.status = TaskStatus.pending,
  });

  factory TaskSyncShareIndustry.deserialize(Map<String, dynamic> json) {
    return TaskSyncShareIndustry(
      params: json['params'] as Map<String, dynamic>,
      priority: TaskPriority.fromVal(json['priority'] as int),
      submitTime: DateTime.fromMillisecondsSinceEpoch(json['submitTime'] as int),
      status: TaskStatus.fromVal(json['status'] as int),
    );
  }

  @override
  Future<void> run() async {
    super.doJob();
    final bkJson = <Map<String, dynamic>>[];
    for (final item in responses!) {
      final bkItem = <String, dynamic>{};
      bkItem['code'] = item['param']['code']; // 板块代号
      bkItem['name'] = item['param']['name']; // 板块名称
      bkItem['pinyin'] = item['param']['pinyin']; // 板块拼音
      bkItem['shares'] = item['response']; //板块成分股代码
      bkJson.add(bkItem);
    }
    final data = jsonEncode(bkJson);
    String filePath = await Config.pathMapFileIndustry;
    debugPrint("写入文件 $filePath");
    await FileTool.saveFile(filePath, data);
  }

  @override
  Future<dynamic> onCompletedUi(TaskCompletedEvent event, dynamic result) async {
    // 加载股票行业信息
    String filePath = await Config.pathMapFileIndustry;
    String data = await FileTool.loadFile(filePath);
    final industries = jsonDecode(data);
    // 填充股票的 industry 字段
    StoreQuote.fillShareIndustry(industries);
    // 通知UI更新
  }
}
