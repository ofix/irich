// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/rich_widgets/rich_widget_provider_concept.dart
// Purpose:     riverpod provider for rich concept widget
// Author:      songhuabiao
// Created:     2025-07-03 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/rich_widgets/rich_widget_provider.dart';

// 概念列表
final richWidgetConceptProviders = StateNotifierProvider.autoDispose
    .family<RichWidgetConceptNotifier, List<ShareConcept>, RichWidgetParams>((ref, params) {
      final notifier = RichWidgetConceptNotifier(ref: ref, params: params);
      return notifier;
    });

class RichWidgetConceptNotifier extends StateNotifier<List<ShareConcept>> {
  RichWidgetParams params;
  Ref ref;
  RichWidgetConceptNotifier({required this.ref, required this.params}) : super([]);
}
