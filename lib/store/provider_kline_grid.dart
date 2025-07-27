// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/provider_kline_grid.dart
// Purpose:     kline ctrl grid wnd provider
// Author:      songhuabiao
// Created:     2025-07-23 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/provider_kline_ctrl.dart';
import 'package:irich/store/state_quote.dart';

enum ShareGridLayout {
  twoByTwo,
  threeByTwo,
  threeByThree,
  fourByFour;

  int getBoundary() {
    switch (this) {
      case ShareGridLayout.twoByTwo:
        return 2 * 2; // 4
      case ShareGridLayout.threeByTwo:
        return 3 * 2; // 6
      case ShareGridLayout.threeByThree:
        return 3 * 3; // 9
      case ShareGridLayout.fourByFour:
        return 4 * 4; // 16
    }
  }
}

class SubGridKline {
  KlineType klineType;
  String shareCode;

  SubGridKline({required this.klineType, required this.shareCode});

  SubGridKline copyWith({KlineType? klineType, String? shareCode}) {
    return SubGridKline(
      klineType: klineType ?? this.klineType,
      shareCode: shareCode ?? this.shareCode,
    );
  }
}

class GridKlineState {
  List<SubGridKline> shares; // key: 股票代码
  List<List<SubGridKline>> history; // 历史股票
  int startBoundary; // 截取排好序的股票列表
  int activePos; // 当前聚焦的股票下标
  ShareGridLayout layout;

  GridKlineState({
    required this.shares,
    this.history = const [],
    this.activePos = 0,
    this.startBoundary = 0,
    this.layout = ShareGridLayout.twoByTwo,
  });
  // 实现 copyWith 方法
  GridKlineState copyWith({
    List<SubGridKline>? shares,
    List<List<SubGridKline>>? history,
    int? activePos,
    int? startBoundary,
    ShareGridLayout? layout,
  }) {
    return GridKlineState(
      shares: shares ?? this.shares,
      history: history ?? this.history,
      activePos: activePos ?? this.activePos,
      startBoundary: startBoundary ?? this.startBoundary,
      layout: layout ?? this.layout,
    );
  }
}

class GridKlineNotifier extends StateNotifier<GridKlineState> {
  final Ref ref;
  GridKlineNotifier({required this.ref}) : super(GridKlineState(shares: [], activePos: 0));

  // 复用原有KlineCtrlNotifier的逻辑
  void addShare(String shareCode, KlineType klineType) {
    final subGridKline = SubGridKline(klineType: klineType, shareCode: shareCode);
    final shares = state.shares;
    shares.add(subGridKline);
    state = state.copyWith(shares: shares);
  }

  // 更新指定位置的股票
  void updateShare(int pos, String shareCode, KlineType klineType) {
    if (pos > state.shares.length) {
      return;
    }
    final shares = state.shares;
    shares[pos] = SubGridKline(klineType: klineType, shareCode: shareCode);
    state = state.copyWith(shares: shares);
  }

  // 下一批股票
  void nextSubShareList() {
    final shareList = ref.read(shareListProvider);
    final subShares = shareList.sublist(
      state.startBoundary,
      state.startBoundary + state.layout.getBoundary(),
    );
    final newShares = <SubGridKline>[];
    final history = state.history;
    history.add(state.shares);
    for (int i = 0; i < subShares.length; i++) {
      newShares.add(
        SubGridKline(klineType: state.shares[i].klineType, shareCode: subShares[i].code),
      );
    }
    state = state.copyWith(history: history, shares: newShares);
  }

  // 上一批股票
  void prevSubShareList() {
    if (state.history.isNotEmpty) {
      List<SubGridKline> subShares = state.history.removeLast();
      state.copyWith(shares: subShares);
    }
  }
}

final gridKlinePanelProvider = StateNotifierProvider<GridKlineNotifier, GridKlineState>((ref) {
  return GridKlineNotifier(ref: ref);
});

final gridKlineCtrlProviders =
    StateNotifierProvider.family<KlineCtrlNotifier, KlineCtrlState, String>((ref, shareCode) {
      final notifier = KlineCtrlNotifier(
        ref: ref,
        shareCode: shareCode,
        wndMode: KlineWndMode.mini,
        klineType: KlineType.day,
      );
      return notifier;
    });
