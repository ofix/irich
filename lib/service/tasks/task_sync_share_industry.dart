// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/tasks/task_sync_share_industry.dart
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
import 'package:irich/service/tasks/batch_api_task.dart';
import 'package:irich/service/tasks/task.dart';
import 'package:irich/service/task_events.dart';
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

  TaskSyncShareIndustry.build(super.json)
    : type = TaskType.fromVal(json['Type'] as int),
      apiType = ProviderApiType.fromVal(json['ApiType'] as int),
      super.build();

  @override
  Future<void> run() async {
    super.doJob();
    final bkJson = <Map<String, dynamic>>[];
    for (final item in responses!) {
      final bkItem = <String, dynamic>{};
      bkItem['Code'] = item['Params']['code']; // 板块代号
      bkItem['Name'] = item['Params']['name']; // 板块名称
      bkItem['Pinyin'] = item['Params']['pinyin']; // 板块拼音
      bkItem['Shares'] = item['Response']; //板块成分股代码
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
