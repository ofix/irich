// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/task_sync_share_quote.dart
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
import 'package:irich/service/task_scheduler/task.dart';
import 'package:irich/utils/file_tool.dart';

class TaskSyncShareQuote extends Task {
  TaskSyncShareQuote({
    required super.type,
    required super.params,
    super.priority = TaskPriority.immediate,
    super.submitTime,
    super.status,
  });
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
        'code': share.code,
        'name': share.name,
        'market': share.market.market,
        'price_yesterday_close': share.priceYesterdayClose,
        'price_now': share.priceNow,
        'price_min': share.priceMin,
        'price_max': share.priceMax,
        'price_open': share.priceOpen,
        'price_close': share.priceClose ?? share.priceNow,
        'price_amplitude': share.priceAmplitude,
        // 'change_amount': share.changeAmount,
        'change_rate': share.changeRate,
        'volume': share.volume,
        'amount': share.amount,
        'turnover_rate': share.turnoverRate,
        'qrr': share.qrr,
      };
      result.add(jsonObj);
    }
    const encoder = JsonEncoder.withIndent('    ');
    return encoder.convert(result);
  }
}
