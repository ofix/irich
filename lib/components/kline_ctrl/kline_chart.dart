// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/kline_ctrl/KlineChart.dart
// Purpose:     kline chart
// Author:      songhuabiao
// Created:     2025-05-22 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/components/kline_ctrl/kline_chart_painter.dart';
import 'package:irich/components/kline_ctrl/kline_ema_curve_buttons.dart';
import 'package:irich/store/provider_kline_ctrl.dart';
import 'package:irich/theme/stock_colors.dart';

class KlineChart extends ConsumerStatefulWidget {
  final StockColors stockColors;
  final String shareCode;
  const KlineChart({super.key, required this.stockColors, required this.shareCode});

  @override
  ConsumerState<KlineChart> createState() => _KlineChartState();
}

class _KlineChartState extends ConsumerState<KlineChart> {
  // EMA日K线
  int emaCurveChanged = 0;
  @override
  Widget build(BuildContext context) {
    ref.watch(
      klineCtrlProvider.select(
        (state) => (
          state.klineChartWidth,
          state.klineStep,
          state.klineRng.begin,
          state.klineRng.end,
          state.klineWidth,
          state.klineRngMinPrice,
          state.klineRngMaxPrice,
          state.emaCurves,
          state.klineType,
        ),
      ),
    );
    final state = ref.read(klineCtrlProvider);
    return Container(
      width: state.klineCtrlWidth,
      height: state.klineType.isMinuteType ? state.klineChartHeight : state.klineChartHeight + 22,
      color: const Color.fromARGB(255, 24, 24, 24 /*28, 29, 33*/),
      child: Stack(
        children: [
          if (!state.klineType.isMinuteType)
            Positioned(top: -KlineCtrlLayout.titleBarMargin, child: KlineEmaCurveButtons()),
          Positioned(
            top: state.klineType.isMinuteType ? 0 : 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 强制左对齐
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size(state.klineCtrlWidth, state.klineChartHeight),
                    painter: KlinePainter(
                      share: state.share!,
                      klineChartWidth: state.klineChartWidth,
                      klineChartHeight: state.klineChartHeight,
                      klineChartLeftMargin: state.klineChartLeftMargin,
                      klineChartRightMargin: state.klineChartRightMargin,
                      klineType: state.klineType,
                      klines: state.klines,
                      minuteKlines: state.minuteKlines,
                      fiveDayMinuteKlines: state.fiveDayMinuteKlines,
                      klineRngBegin: state.klineRng.begin,
                      klineRngEnd: state.klineRng.end,
                      klineRngMinPrice: state.klineRngMinPrice,
                      klineRngMaxPrice: state.klineRngMaxPrice,
                      emaCurves: state.emaCurves,
                      emaCurveChanged: emaCurveChanged,
                      crossLineFollowKlineIndex: state.crossLineFollowKlineIndex,
                      klineStep: state.klineStep,
                      klineWidth: state.klineWidth,
                      stockColors: widget.stockColors,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
