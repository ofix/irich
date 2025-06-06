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
  final KlineState klineState;
  final StockColors stockColors;
  const CrossLineChart({super.key, required this.klineState, required this.stockColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: klineState.klineChartWidth,
      height: klineState.klineCtrlHeight - klineState.klineCtrlTitleBarHeight,
      color: Colors.transparent,
      child: CustomPaint(
        painter: CrossLinePainter(
          klines: klineState.klines,
          klineCtrlTitleBarHeight: klineState.klineCtrlTitleBarHeight,
          klineChartWidth: klineState.klineChartWidth,
          klineChartHeight: klineState.klineChartHeight,
          klineChartLeftMargin: klineState.klineChartLeftMargin,
          klineChartRightMargin: klineState.klineChartRightMargin,
          klineType: klineState.klineType,
          minuteKlines: klineState.minuteKlines,
          fiveDayMinuteKlines: klineState.fiveDayMinuteKlines,
          klineRng: klineState.klineRng!,
          klineRngMinPrice: klineState.klineRngMinPrice,
          klineRngMaxPrice: klineState.klineRngMaxPrice,
          crossLineMode: klineState.crossLineMode,
          crossLineFollowKlineIndex: klineState.crossLineFollowKlineIndex,
          crossLineFollowCursorPos: klineState.crossLineFollowCursorPos,
          klineStep: klineState.klineStep,
          klineWidth: klineState.klineWidth,
          stockColors: stockColors,
        ),
      ),
    );
  }
}
