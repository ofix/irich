// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/rich_widgets/rich_widget_provider_industry.dart
// Purpose:     riverpod provider for industry list rich widget
// Author:      songhuabiao
// Created:     2025-07-03 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/rich_widgets/rich_widget_provider.dart';

// 行业列表
final richWidgetIndustryProviders = StateNotifierProvider.autoDispose
    .family<RichWidgetIndustryNotifier, List<ShareIndustry>, RichWidgetParams>((ref, params) {
      final notifier = RichWidgetIndustryNotifier(ref: ref, params: params);
      return notifier;
    });

class RichWidgetIndustryNotifier extends StateNotifier<List<ShareIndustry>> {
  RichWidgetParams params;
  Ref ref;
  RichWidgetIndustryNotifier({required this.ref, required this.params}) : super([]);
}
