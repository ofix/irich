// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/tasks/task_sync_stock_index.dart
// Purpose:     synchronize stock indexes
// Author:      songhuabiao
// Created:     2025-06-16 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
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

class TaskSyncStockIndex extends Task<List<StockIndex>> {
  @override
  TaskType type = TaskType.syncShareQuote;
  TaskSyncStockIndex({
    required super.params,
    super.priority = TaskPriority.immediate,
    super.submitTime,
    super.status,
  });

  TaskSyncStockIndex.build(super.json)
    : type = TaskType.fromVal(json['Type'] as int),
      super.build();

  @override
  Future<List<StockIndex>> run() async {
    final (statusQuote, result as List<StockIndex>) = await ApiService(
      ProviderApiType.indexList,
    ).fetch("");
    if (statusQuote.ok()) {
      await _saveQuoteFile(await Config.pathDataFileQuote, result); // 保存行情数据到文件
    }
    return result;
  }

  Future<bool> _saveQuoteFile(String filePath, List<StockIndex> stockIndexes) async {
    String data = _dumpStockIndexes(stockIndexes);
    return FileTool.saveFile(filePath, data);
  }

  String _dumpStockIndexes(List<StockIndex> stockIndexes) {
    final result = <Map<String, dynamic>>[];

    for (final index in stockIndexes) {
      final jsonObj = <String, dynamic>{
        'Code': index.code,
        'Name': index.name,
        'PriceYesterdayClose': index.priceYesterdayClose,
        'PriceNow': index.priceNow,
        'PriceMin': index.priceMin,
        'PriceMax': index.priceMax,
        'PriceOpen': index.priceOpen,
        'PriceClose': index.priceClose ?? index.priceNow,
        'PriceAmplitude': index.priceAmplitude,
        // 'change_amount': index.changeAmount,
        'ChangeRate': index.changeRate,
        'Volume': index.volume,
        'Amount': index.amount,
      };
      result.add(jsonObj);
    }
    const encoder = JsonEncoder.withIndent('    ');
    return encoder.convert(result);
  }
}
