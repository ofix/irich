// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/rich_widgets/rich_widget_provider_watch_list.dart
// Purpose:     riverpod provider for watch list rich widget
// Author:      songhuabiao
// Created:     2025-07-03 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/global/stock.dart';

// 自选股列表控件family数据源参数
class RichWidgetWatchListParams {
  final int panelId; // 面板ID
  final int groupId; // 分组ID

  RichWidgetWatchListParams({required this.panelId, required this.groupId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RichWidgetWatchListParams &&
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

final richWidgetWatchListProviders = StateNotifierProvider.autoDispose
    .family<RichWidgetWatchListNotifier, List<Share>, RichWidgetWatchListParams>((ref, params) {
      final notifier = RichWidgetWatchListNotifier(ref: ref, params: params);
      return notifier;
    });

class RichWidgetWatchListNotifier extends StateNotifier<List<Share>> {
  RichWidgetWatchListParams params;
  Ref ref;
  RichWidgetWatchListNotifier({required this.ref, required this.params}) : super([]);
}
