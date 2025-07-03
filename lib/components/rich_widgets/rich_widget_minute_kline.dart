// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/rich_widget/rich_widget_minute_kline.dart
// Purpose:     minute kline rich widget
// Author:      songhuabiao
// Created:     2025-07-02 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/kline_ctrl/kline_ctrl.dart';
import 'package:irich/components/rich_widgets/rich_widget.dart';
import 'package:irich/store/rich_widgets/rich_widget_provider.dart';

// 股票分时图
class RichWidgetMinuteKline extends RichWidget {
  const RichWidgetMinuteKline({super.key, required super.panelId, super.groupId = 0});
  @override
  ConsumerState<RichWidgetMinuteKline> createState() => _RichWidgetMinuteKlineState();
}

class _RichWidgetMinuteKlineState extends ConsumerState<RichWidgetMinuteKline> {
  @override
  Widget build(BuildContext context) {
    // 监听指定名称的面板的指定数据
    ref.watch(
      richPanelProviders(RichWidgetParams(panelId: widget.panelId, groupId: widget.groupId)),
    );
    return KlineCtrl();
  }
}
