// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/kline_ctrl/cross_line_chart.dart
// Purpose:     cross line chart
// Author:      songhuabiao
// Created:     2025-06-06 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/cross_line_painter.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/theme/stock_colors.dart';

class CrossLineChart extends StatelessWidget {
  final KlineCtrlState klineCtrlState;
  final StockColors stockColors;
  const CrossLineChart({super.key, required this.klineCtrlState, required this.stockColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: klineCtrlState.klineChartWidth,
      height: klineCtrlState.klineCtrlHeight - klineCtrlState.klineCtrlTitleBarHeight - 24,
      color: Colors.transparent,
      child: CustomPaint(
        painter: CrossLinePainter(
          klines: klineCtrlState.klines,
          klineCtrlTitleBarHeight: klineCtrlState.klineCtrlTitleBarHeight,
          klineChartWidth: klineCtrlState.klineChartWidth,
          klineChartHeight: klineCtrlState.klineChartHeight,
          klineChartLeftMargin: klineCtrlState.klineChartLeftMargin,
          klineChartRightMargin: klineCtrlState.klineChartRightMargin,
          klineType: klineCtrlState.klineType,
          minuteKlines: klineCtrlState.minuteKlines,
          fiveDayMinuteKlines: klineCtrlState.fiveDayMinuteKlines,
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
