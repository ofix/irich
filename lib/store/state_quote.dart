// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/state_quote.dart
// Purpose:     quote page state
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

// 行情列表数据
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/global/stock.dart';

class QuoteNotifier extends StateNotifier<AsyncValue<List<Share>>> {
  QuoteNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      // 初始加载数据
      await StoreQuote.load();
      state = AsyncValue.data(StoreQuote.shares);
      // 定时刷新数据
      // ignore: prefer_typing_uninitialized_variables
      var timer = Stream.periodic(const Duration(seconds: 1));
      timer.listen((_) async {
        await StoreQuote.refresh();
        state = AsyncValue.data(StoreQuote.shares);
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// 行情列表数据Provider
final quoteProvider = StateNotifierProvider<QuoteNotifier, AsyncValue<List<Share>>>(
  (ref) => QuoteNotifier(),
);

// 状态管理类
class ShareListNotifier extends StateNotifier<List<Share>> {
  ShareListNotifier() : super([]) {
    // 初始化示例数据（可替换为实际数据源）
    final shares = StoreQuote.shares;
    bool sortDescending = true;
    shares.sort(
      (a, b) =>
          sortDescending
              ? b.changeRate.compareTo(a.changeRate)
              : a.changeRate.compareTo(b.changeRate),
    );
    state = shares;
  }
}

// 创建 RiverPod 提供者
final shareListProvider = StateNotifierProvider<ShareListNotifier, List<Share>>(
  (ref) => ShareListNotifier(),
);

class CurrentShareIndexNotifier extends StateNotifier<int> {
  final Ref _ref;

  CurrentShareIndexNotifier(this._ref) : super(0) {
    // 初始化时默认选中第一个股票（如果列表非空）
    final shares = _ref.read(shareListProvider);
    state = shares.isEmpty ? -1 : 0;
  }

  // 上一个股票
  void previous() {
    final shares = _ref.read(shareListProvider);
    if (shares.isEmpty) return;
    state = (state - 1).clamp(0, shares.length - 1);
  }

  // 下一个股票
  void next() {
    final shares = _ref.read(shareListProvider);
    if (shares.isEmpty) return;
    state = (state + 1).clamp(0, shares.length - 1);
  }

  // 设置选中的股票
  void setSelected(int index) {
    final shares = _ref.read(shareListProvider);
    if (shares.isEmpty) return;
    state = index.clamp(0, shares.length - 1);
  }

  // 跳转到指定索引
  void jumpTo(int index) {
    final shares = _ref.read(shareListProvider);
    if (shares.isEmpty) return;
    state = index.clamp(0, shares.length - 1);
  }
}

final currentShareIndexProvider = StateNotifierProvider<CurrentShareIndexNotifier, int>(
  (ref) => CurrentShareIndexNotifier(ref),
);

// 创建全局 ScrollController 提供者
final scrollControllerProvider = Provider<ScrollController>((ref) {
  final controller = ScrollController();
  ref.onDispose(() => controller.dispose()); // 自动释放资源
  return controller;
});

final favoriteTabScrollControllerProvider = Provider<ScrollController>((ref) {
  final controller = ScrollController();
  ref.onDispose(() => controller.dispose()); // 自动释放资源
  return controller;
});

final lastScrollOffsetProvider = StateProvider<double>((ref) => 0.0);

// 在全局 Provider 中定义 Tab 索引状态
final shareTabIndexProvider = StateProvider<int>((ref) => 0);
