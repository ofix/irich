// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/state_quote.dart
// Purpose:     quote page state
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

// 行情列表数据
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
  int _selectedIndex = 0; // 私有索引，避免外部直接修改

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

  // 获取当前选中股票
  Share get currentShare => state[_selectedIndex];

  // 获取选中索引
  int get selectedIndex => _selectedIndex;

  void prevShare() {
    final int newIndex = _selectedIndex - 1;
    _selectedIndex = newIndex.clamp(0, state.length - 1);
    state = [...state]; // 触发
  }

  // 切换股票（向上/向下）
  void nextShare() {
    final int newIndex = _selectedIndex + 1;
    _selectedIndex = newIndex.clamp(0, state.length - 1);
    state = [...state]; // 触发状态更新
  }

  // 直接设置选中索引（用于列表点击）
  void setSelectedIndex(int index) {
    _selectedIndex = index.clamp(0, state.length - 1);
    state = [...state]; // 触发状态更新
  }
}

// 创建 RiverPod 提供者
final shareListProvider = StateNotifierProvider<ShareListNotifier, List<Share>>(
  (ref) => ShareListNotifier(),
);

// 便捷提供者：直接获取选中股票
final currentShareProvider = Provider<Share>((ref) {
  final shareList = ref.watch(shareListProvider);
  final notifier = ref.watch(shareListProvider.notifier);
  return shareList[notifier.selectedIndex];
});

// 便捷提供者：获取选中索引
final currentShareIndexProvider = Provider<int>((ref) {
  final notifier = ref.watch(shareListProvider.notifier);
  return notifier.selectedIndex;
});
