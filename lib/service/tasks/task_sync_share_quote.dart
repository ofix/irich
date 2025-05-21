// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/tasks/task_sync_share_quote.dart
// Purpose:     synchronize share quote
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////\

import 'dart:async';
import 'dart:convert';

import 'package:irich/global/config.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/service/api_provider_capabilities.dart';
import 'package:irich/service/api_service.dart';
import 'package:irich/service/tasks/task.dart';
import 'package:irich/utils/file_tool.dart';

class TaskSyncShareQuote extends Task<List<Share>> {
  @override
  TaskType type = TaskType.syncShareQuote;
  TaskSyncShareQuote({
    required super.params,
    super.priority = TaskPriority.immediate,
    super.submitTime,
    super.status,
  });

  factory TaskSyncShareQuote.deserialize(Map<String, dynamic> json) {
    return TaskSyncShareQuote(
      params: json['Params'] as Map<String, dynamic>,
      priority: TaskPriority.fromVal(json['Priority'] as int),
      submitTime: DateTime.fromMicrosecondsSinceEpoch(json['SubmitTime']),
      status: TaskStatus.fromVal(json['Status'] as int),
    );
  }

  @override
  Future<List<Share>> run() async {
    final (statusQuote, resultQuote as List<Share>) = await ApiService(
      ProviderApiType.quote,
    ).fetch("");
    if (statusQuote.ok()) {
      await _saveQuoteFile(await Config.pathDataFileQuote, resultQuote); // 保存行情数据到文件
    }
    return resultQuote;
  }

  Future<bool> _saveQuoteFile(String filePath, List<Share> shares) async {
    String data = _dumpQuote(shares);
    return FileTool.saveFile(filePath, data);
  }

  String _dumpQuote(List<Share> shares) {
    final result = <Map<String, dynamic>>[];

    for (final share in shares) {
      final jsonObj = <String, dynamic>{
        'Code': share.code,
        'Name': share.name,
        'Market': share.market.market,
        'PriceYesterdayClose': share.priceYesterdayClose,
        'PriceNow': share.priceNow,
        'PriceMin': share.priceMin,
        'PriceMax': share.priceMax,
        'PriceOpen': share.priceOpen,
        'PriceClose': share.priceClose ?? share.priceNow,
        'PriceAmplitude': share.priceAmplitude,
        // 'change_amount': share.changeAmount,
        'ChangeRate': share.changeRate,
        'Volume': share.volume,
        'Amount': share.amount,
        'TurnoverRate': share.turnoverRate,
        'Qrr': share.qrr,
      };
      result.add(jsonObj);
    }
    const encoder = JsonEncoder.withIndent('    ');
    return encoder.convert(result);
  }
}
