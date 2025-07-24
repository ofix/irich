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

class MultiKlineState {
  final Map<String, KlineCtrlState> shares; // key: 股票代码
  final String activeShare; // 当前聚焦的股票
  final KlineType klineType; // 全局K线类型

  MultiKlineState({
    required this.shares,
    required this.activeShare,
    this.klineType = KlineType.day,
  });
  // 实现 copyWith 方法
  MultiKlineState copyWith({
    Map<String, KlineCtrlState>? shares,
    String? activeShare,
    KlineType? klineType,
  }) {
    return MultiKlineState(
      shares: shares ?? this.shares,
      activeShare: activeShare ?? this.activeShare,
      klineType: klineType ?? this.klineType,
    );
  }
}

class MultiKlineNotifier extends StateNotifier<MultiKlineState> {
  final Ref ref;
  MultiKlineNotifier({required this.ref})
    : super(MultiKlineState(shares: {}, activeShare: '', klineType: KlineType.day));

  // 复用原有KlineCtrlNotifier的逻辑
  void addShare(String shareCode) {
    final notifier = KlineCtrlNotifier(ref: ref, shareCode: shareCode, klineType: state.klineType);
    state = state.copyWith(shares: {...state.shares, shareCode: notifier.state});
  }

  void addShareList(List<String> shareCodes) {
    final newShares = Map.fromEntries(
      shareCodes.map(
        (code) => MapEntry(
          code,
          KlineCtrlNotifier(ref: ref, shareCode: code, klineType: state.klineType).state,
        ),
      ),
    );
    state = state.copyWith(shares: {...state.shares, ...newShares});
  }

  // 全局切换K线类型
  void changeKlineType(KlineType type) {
    final newShares = Map.fromEntries(
      state.shares.entries.map((e) {
        final notifier = KlineCtrlNotifier(ref: ref, shareCode: e.key, klineType: type);
        return MapEntry(e.key, notifier.state);
      }),
    );
    state = state.copyWith(klineType: type, shares: newShares);
  }
}

final multiKlineProvider = StateNotifierProvider<MultiKlineNotifier, MultiKlineState>((ref) {
  return MultiKlineNotifier(ref: ref);
});

final klineGridProvider = StateNotifierProvider.autoDispose
    .family<KlineCtrlNotifier, KlineCtrlState, String>((ref, shareCode) {
      return KlineCtrlNotifier(
        ref: ref,
        shareCode: shareCode,
        wndMode: KlineWndMode.mini,
        klineType: KlineType.day,
      );
    });
