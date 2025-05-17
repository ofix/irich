// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/task_sync_share_region.dart
// Purpose:     synchronize share region task
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:irich/global/config.dart';
import 'package:irich/service/api_provider_capabilities.dart';
import 'package:irich/service/task_scheduler/batch_api_task.dart';
import 'package:irich/service/task_scheduler/task.dart';
import 'package:irich/service/task_scheduler/task_events.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/utils/file_tool.dart';

class TaskSyncShareRegion extends BatchApiTask {
  @override
  TaskType type = TaskType.syncShareRegion;
  @override
  ProviderApiType apiType = ProviderApiType.province;
  TaskSyncShareRegion({required super.params, super.priority, super.submitTime, super.status});

  factory TaskSyncShareRegion.deserialize(Map<String, dynamic> json) {
    return TaskSyncShareRegion(
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
    String filePath = await Config.pathMapFileProvince;
    debugPrint("写入文件 $filePath");
    await FileTool.saveFile(filePath, data);
  }

  @override
  Future<dynamic> onCompletedUi(TaskCompletedEvent event, dynamic result) async {
    // 加载股票地域信息
    String filePath = await Config.pathMapFileProvince;
    String data = await FileTool.loadFile(filePath);
    final provinces = jsonDecode(data);
    // 填充股票的province字段
    StoreQuote.fillShareProvince(provinces);
    // 通知UI更新
  }
}
