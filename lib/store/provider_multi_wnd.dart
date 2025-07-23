// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/provider_multi_wnd.dart
// Purpose:     multi kline ctrl wnd provider
// Author:      songhuabiao
// Created:     2025-07-23 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/global/stock.dart';

class MultiWndParams {
  final String shareCode;
  final KlineWndMode wndMode;
  final KlineType klineType;

  MultiWndParams({
    required this.shareCode,
    this.wndMode = KlineWndMode.full, // 类内定义默认值
    this.klineType = KlineType.day,
  });
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MultiWndParams && shareCode == other.shareCode);

  @override
  int get hashCode => shareCode.hashCode;
}
