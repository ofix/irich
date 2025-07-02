// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/panels/minute_kline_rich_panel.dart
// Purpose:     minute kline rich panel
// Author:      songhuabiao
// Created:     2025-07-02 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/panels/rich_panel.dart';
import 'package:irich/store/provider_rich_panel.dart';

// 市场行情列表
class QuoteRichPanel extends RichPanel {
  const QuoteRichPanel({super.key, required super.name, super.groupId = 0});
  @override
  ConsumerState<QuoteRichPanel> createState() => _QuoteRichPanelState();
}

class _QuoteRichPanelState extends ConsumerState<QuoteRichPanel> {
  @override
  Widget build(BuildContext context) {
    // 监听指定名称的面板的指定数据
    ref.watch(richPanelProviders(RichPanelParams(name: widget.name, groupId: widget.groupId)));
    return Container();
  }
}
