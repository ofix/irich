// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/rich_widgets/rich_widget_provider.dart
// Purpose:     riverpod provider for base rich widget
// Author:      songhuabiao
// Created:     2025-07-02 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter_riverpod/flutter_riverpod.dart';

// 当前自定义面板参数，通过面板名称进行区分
class RichWidgetParams {
  final int panelId;
  final int groupId;

  RichWidgetParams({required this.panelId, required this.groupId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RichWidgetParams &&
          runtimeType == other.runtimeType &&
          panelId == other.panelId &&
          groupId == other.groupId);

  @override
  int get hashCode => Object.hash(panelId, groupId);
}

final richPanelProviders = StateNotifierProvider.autoDispose
    .family<RichPanelNotifier, Map<String, dynamic>, RichWidgetParams>((ref, params) {
      return RichPanelNotifier();
    });

class RichPanelNotifier extends StateNotifier<Map<String, dynamic>> {
  Map<String, dynamic> config = {};
  String configPath = "";
  RichPanelNotifier() : super({});
  void updatePanelState(String ctrlName, String method, Map<String, dynamic>? config) {}
}
