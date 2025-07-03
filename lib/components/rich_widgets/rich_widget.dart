// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/rich_widgets/rich_widget.dart
// Purpose:     rich widget base class
// Author:      songhuabiao
// Created:     2025-07-02 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/rich_widgets/rich_widget_concept_list.dart';
import 'package:irich/components/rich_widgets/rich_widget_industry_list.dart';
import 'package:irich/components/rich_widgets/rich_widget_kline.dart';
import 'package:irich/components/rich_widgets/rich_widget_market_list.dart';
import 'package:irich/components/rich_widgets/rich_widget_minute_kline.dart';
import 'package:irich/components/rich_widgets/rich_widget_quote.dart';
import 'package:irich/components/rich_widgets/rich_widget_region_list.dart';
import 'package:irich/components/rich_widgets/rich_widget_watch_list.dart';

class RichWidget extends ConsumerStatefulWidget {
  final int panelId; // 面板名称
  final int groupId; // 分组ID
  const RichWidget({super.key, required this.panelId, required this.groupId});

  @override
  ConsumerState<RichWidget> createState() => _RichWidgetState();
}

class _RichWidgetState extends ConsumerState<RichWidget> {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}

class RichWidgetFactory {
  static Widget build(
    int panelId,
    int groupId,
    String ctrlName,
    WidgetRef ref, {
    required void Function(String eventType, [dynamic payload]) onEvent,
  }) {
    switch (ctrlName) {
      case 'DayKline': // 日K线
        return RichWidgetKline(panelId: panelId, groupId: groupId);
      case 'MinuteKline': // 分时图
        return RichWidgetMinuteKline(panelId: panelId, groupId: groupId);
      case 'Quote': // 市场行情列表
        return RichWidgetQuote(panelId: panelId, groupId: groupId);
      case 'ConceptList': // 概念板块列表
        return RichWidgetConceptList(panelId: panelId, groupId: groupId);
      case 'IndustryList': // 行业板块列表
        return RichWidgetIndustryList(panelId: panelId, groupId: groupId);
      case 'RegionList': // 地域板块列表
        return RichWidgetRegionList(panelId: panelId, groupId: groupId);
      case 'MarketList': // 市场行情个股
        return RichWidgetMarketList(panelId: panelId, groupId: groupId);
      case 'WatchList': // 自选股列表
        return RichWidgetWatchList(panelId: panelId, groupId: groupId);
      default:
        throw UnimplementedError("unsupport control $ctrlName");
    }
  }
}
