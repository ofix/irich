// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/rich_panel_provider.dart
// Purpose:     rich panel provider
// Author:      songhuabiao
// Created:     2025-07-02 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter_riverpod/flutter_riverpod.dart';

// 当前自定义面板参数，通过面板名称进行区分
class RichPanelParams {
  final String name;
  final int groupId;

  RichPanelParams({required this.name, required this.groupId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RichPanelParams &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          groupId == other.groupId);

  @override
  int get hashCode => Object.hash(name, groupId);
}

final richPanelProviders =
    StateNotifierProvider.family<RichPanelNotifier, Map<String, dynamic>, RichPanelParams>((
      ref,
      params,
    ) {
      return RichPanelNotifier();
    });

class RichPanelNotifier extends StateNotifier<Map<String, dynamic>> {
  Map<String, dynamic> config = {};
  String configPath = "";
  RichPanelNotifier() : super({});
  void updatePanelState(String ctrlName, String method, Map<String, dynamic>? config) {}
}
