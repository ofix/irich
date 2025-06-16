// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/store_index.dart
// Purpose:     stock index store
// Author:      songhuabiao
// Created:     2025-06-16 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/global/stock.dart';
import 'package:irich/service/task_scheduler.dart';
import 'package:irich/service/tasks/task_sync_stock_index.dart';
import 'package:irich/utils/chinese_pinyin.dart';
import 'package:irich/utils/rich_result.dart';
import 'package:irich/utils/trie.dart';

class StoreIndex {
  static List<StockIndex> stockIndex = [];

  /// 私有构造函数防止实例化
  StoreIndex._();

  // 只加载行情数据，不保存到文件，用于定时刷新行情数据
  static Future<RichResult> loadQuote() async {
    final scheduler = await TaskScheduler.getInstance();
    final newIndexes = await scheduler.addTask(TaskSyncStockIndex(params: {}));
    return success();
  }

  /// 构建指数Trie树
  static Future<void> _buildIndexTrie(List<StockIndex> stockIndexes, Trie trie) async {
    // 创建指数Trie树，支持指数搜索
    for (final stockIndex in stockIndexes) {
      trie.insert(stockIndex.name, stockIndex.code);
      trie.insert(stockIndex.code, stockIndex.code);
      // 插入拼音
      List<String> pinyin = await ChinesePinYin.getFirstLetters(stockIndex.name);
      for (final char in pinyin) {
        trie.insert(char.toLowerCase(), stockIndex.code);
      }
    }
  }
}
