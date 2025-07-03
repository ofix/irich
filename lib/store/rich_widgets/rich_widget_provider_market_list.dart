// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/rich_widgets/rich_widget_provider_market_list.dart
// Purpose:     riverpod provider for market list rich widget
// Author:      songhuabiao
// Created:     2025-07-03 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/global/stock.dart';

// 市场行情列表family数据源参数
class RichWidgetMarketListParams {
  final int panelId; // 面板ID
  final int groupId; // 分组ID

  RichWidgetMarketListParams({required this.panelId, required this.groupId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RichWidgetMarketListParams &&
          runtimeType == other.runtimeType &&
          panelId == other.panelId &&
          groupId == other.groupId);

  @override
  int get hashCode => panelId.hashCode ^ groupId.hashCode;

  // Optional: Add toString() for better debugging
  @override
  String toString() {
    return 'RichWidgetKlineParams{panelId: $panelId, groupId: $groupId}';
  }
}

final richWidgetMarketListProviders = StateNotifierProvider.autoDispose
    .family<RichWidgetMarketListNotifier, List<Share>, RichWidgetMarketListParams>((ref, params) {
      final notifier = RichWidgetMarketListNotifier(ref: ref, params: params);
      return notifier;
    });

class RichWidgetMarketListNotifier extends StateNotifier<List<Share>> {
  RichWidgetMarketListParams params;
  Ref ref;
  RichWidgetMarketListNotifier({required this.ref, required this.params}) : super([]);
}
