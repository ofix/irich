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
import 'package:irich/components/kline_ctrl/kline_ctrl.dart';
import 'package:irich/components/panels/rich_panel.dart';
import 'package:irich/store/provider_rich_panel.dart';

// 股票分时图
class MinuteKlineRichPanel extends RichPanel {
  const MinuteKlineRichPanel({super.key, required super.name, super.groupId = 0});
  @override
  ConsumerState<MinuteKlineRichPanel> createState() => _MinuteKlineRichPanelState();
}

class _MinuteKlineRichPanelState extends ConsumerState<MinuteKlineRichPanel> {
  @override
  Widget build(BuildContext context) {
    // 监听指定名称的面板的指定数据
    ref.watch(richPanelProviders(RichPanelParams(name: widget.name, groupId: widget.groupId)));
    return KlineCtrl();
  }
}
