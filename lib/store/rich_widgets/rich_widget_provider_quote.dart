// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/rich_widgets/rich_widget_provider_quote.dart
// Purpose:     riverpod provider for quote rich widget
// Author:      songhuabiao
// Created:     2025-07-03 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/rich_widgets/rich_widget_provider.dart';

final richWidgetQuoteProviders = StateNotifierProvider.autoDispose
    .family<RichQuoteCtrlNotifier, List<Share>, RichWidgetParams>((ref, params) {
      final notifier = RichQuoteCtrlNotifier(ref: ref, params: params);
      return notifier;
    });

class RichQuoteCtrlNotifier extends StateNotifier<List<Share>> {
  RichWidgetParams params;
  Ref ref;
  RichQuoteCtrlNotifier({required this.ref, required this.params}) : super([]);
}
