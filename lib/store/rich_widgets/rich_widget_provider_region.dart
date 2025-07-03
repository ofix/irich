// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/rich_widgets/rich_widget_provider_region.dart
// Purpose:     riverpod provider for region list rich widget
// Author:      songhuabiao
// Created:     2025-07-03 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/store/rich_widgets/rich_widget_provider.dart';

// 地域列表
final richWidgetRegionProviders = StateNotifierProvider.autoDispose
    .family<RichWidgetRegionNotifier, List<String>, RichWidgetParams>((ref, params) {
      final notifier = RichWidgetRegionNotifier(ref: ref, params: params);
      return notifier;
    });

class RichWidgetRegionNotifier extends StateNotifier<List<String>> {
  RichWidgetParams params;
  Ref ref;
  RichWidgetRegionNotifier({required this.ref, required this.params}) : super([]);
}
