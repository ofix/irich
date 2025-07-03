// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/rich_widgets/rich_widget_provider_index.dart
// Purpose:     riverpod provider for index rich widget
// Author:      songhuabiao
// Created:     2025-07-03 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/global/stock.dart';

// 指数控件family数据源参数
class RichWidgetIndexParams {
  final int panelId; // 面板ID
  final int groupId; // 分组ID
  final String indexCode; // 指数编号
  final KlineType klineType; // 指数类型

  RichWidgetIndexParams({
    required this.panelId,
    required this.groupId,
    required this.indexCode,
    required this.klineType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RichWidgetIndexParams &&
          runtimeType == other.runtimeType &&
          panelId == other.panelId &&
          groupId == other.groupId &&
          indexCode == other.indexCode &&
          klineType == other.klineType);

  @override
  int get hashCode => panelId.hashCode ^ groupId.hashCode ^ indexCode.hashCode ^ klineType.hashCode;

  // Optional: Add toString() for better debugging
  @override
  String toString() {
    return 'RichWidgetKlineParams{panelId: $panelId, groupId: $groupId}';
  }
}

// 指数列表
final richWidgetIndexProviders = StateNotifierProvider.autoDispose
    .family<RichWidgetIndexNotifier, KlineCtrlState, RichWidgetIndexParams>((ref, params) {
      final notifier = RichWidgetIndexNotifier(ref: ref, params: params);
      return notifier;
    });

class RichWidgetIndexNotifier extends StateNotifier<KlineCtrlState> {
  RichWidgetIndexParams params;
  Ref ref;
  RichWidgetIndexNotifier({required this.ref, required this.params})
    : super(
        KlineCtrlState(
          shareCode: params.indexCode,
          wndMode: KlineWndMode.mini,
          klineType: params.klineType,
        ),
      );
}
