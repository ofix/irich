// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/kline_ctrl/cross_line_chart.dart
// Purpose:     cross line chart
// Author:      songhuabiao
// Created:     2025-06-06 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/kline_ctrl/cross_line_painter.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/store/provider_kline_ctrl.dart';
import 'package:irich/theme/stock_colors.dart';

class CrossLineChart extends ConsumerWidget {
  final StockColors stockColors;
  const CrossLineChart({super.key, required this.stockColors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      klineCtrlProvider.select(
        (state) => (
          state.crossLineMode,
          state.crossLineFollowCursorPos,
          state.crossLineFollowKlineIndex,
          state.klineStep,
        ),
      ),
    );
    final klineCtrlState = ref.read(klineCtrlProvider);
    return SizedBox(
      width: klineCtrlState.klineChartWidth,
      height:
          klineCtrlState.klineCtrlHeight -
          klineCtrlState.klineCtrlTitleBarHeight * 2 +
          KlineCtrlLayout.titleBarMargin,
      child: CustomPaint(
        painter: CrossLinePainter(
          klines: klineCtrlState.klines,
          indicatorChartHeight: klineCtrlState.indicatorChartHeight,
          indicatorChartTitleBarHeight: klineCtrlState.indicatorChartTitleBarHeight,
          klineChartWidth: klineCtrlState.klineChartWidth,
          klineChartHeight: klineCtrlState.klineChartHeight,
          klineChartLeftMargin: klineCtrlState.klineChartLeftMargin,
          klineChartRightMargin: klineCtrlState.klineChartRightMargin,
          klineType: klineCtrlState.klineType,
          minuteKlines: klineCtrlState.minuteKlines,
          fiveDayMinuteKlines: klineCtrlState.fiveDayMinuteKlines,
          indicators: klineCtrlState.indicators,
          klineRng: klineCtrlState.klineRng!,
          klineRngMinPrice: klineCtrlState.klineRngMinPrice,
          klineRngMaxPrice: klineCtrlState.klineRngMaxPrice,
          crossLineMode: klineCtrlState.crossLineMode,
          crossLineFollowKlineIndex: klineCtrlState.crossLineFollowKlineIndex,
          crossLineFollowCursorPos: klineCtrlState.crossLineFollowCursorPos,
          klineStep: klineCtrlState.klineStep,
          klineWidth: klineCtrlState.klineWidth,
          stockColors: stockColors,
        ),
      ),
    );
  }
}
