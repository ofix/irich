// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/panels/rich_panel.dart
// Purpose:     rich panel base class
// Author:      songhuabiao
// Created:     2025-07-02 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/panels/concept_list_rich_panel.dart';
import 'package:irich/components/panels/day_kline_rich_panel.dart';
import 'package:irich/components/panels/minute_kline_rich_panel.dart';
import 'package:irich/components/panels/quote_rich_panel.dart';

class RichPanel extends ConsumerStatefulWidget {
  final String name; // 面板名称
  final int groupId; // 分组ID
  const RichPanel({super.key, required this.name, required this.groupId});

  @override
  ConsumerState<RichPanel> createState() => _RichPanelState();
}

class _RichPanelState extends ConsumerState<RichPanel> {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}

class RichPanelFactory {
  static RichPanel buildPanel(
    String panelName,
    int groupId,
    String ctrlName,
    WidgetRef ref, {
    required void Function(String eventType, [dynamic payload]) onEvent,
  }) {
    switch (ctrlName) {
      case 'DayKline':
        return DayKlineRichPanel(name: panelName, groupId: groupId);
      case 'Quote':
        return QuoteRichPanel(name: panelName, groupId: groupId);
      case 'MinuteKline':
        return MinuteKlineRichPanel(name: panelName, groupId: groupId);
      case 'ConceptList':
        return ConceptListRichPanel(name: panelName, groupId: groupId);
      default:
        throw UnimplementedError("unsupport control $ctrlName");
    }
  }
}
