// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/kline_ctrl/KlineChart.dart
// Purpose:     kline chart
// Author:      songhuabiao
// Created:     2025-05-22 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/components/kline_ctrl/kline_chart_painter.dart';
import 'package:irich/theme/stock_colors.dart';

class KlineChart extends StatefulWidget {
  final KlineState klineState;
  final StockColors stockColors;
  const KlineChart({super.key, required this.klineState, required this.stockColors});

  @override
  State<KlineChart> createState() => _KlineChartState();
}

class _KlineChartState extends State<KlineChart> {
  // EMA日K线
  static const Map<String, int> emaCurveMap = {
    'EMA5': 5,
    'EMA10': 10,
    'EMA20': 20,
    'EMA30': 30,
    'EMA60': 60,
    'EMA255': 255,
    'EMA905': 905,
  };
  @override
  Widget build(BuildContext context) {
    return Container(
      width:
          widget.klineState.klineChartWidth +
          widget.klineState.klineChartLeftMargin +
          widget.klineState.klineChartRightMargin,
      height: widget.klineState.klineChartHeight,
      color: const Color.fromARGB(255, 28, 29, 33),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 强制左对齐
        children: [
          if (!widget.klineState.klineType.isMinuteType)
            _buildEmaCurveButtons(context, emaCurveMap),
          CustomPaint(
            painter: KlinePainter(
              share: widget.klineState.share,
              klineChartWidth: widget.klineState.klineChartWidth,
              klineChartHeight: widget.klineState.klineChartHeight,
              klineChartLeftMargin: widget.klineState.klineChartLeftMargin,
              klineChartRightMargin: widget.klineState.klineChartRightMargin,
              klineType: widget.klineState.klineType,
              klines: widget.klineState.klines,
              minuteKlines: widget.klineState.minuteKlines,
              fiveDayMinuteKlines: widget.klineState.fiveDayMinuteKlines,
              klineRng: widget.klineState.klineRng!,
              klineRngMinPrice: widget.klineState.klineRngMinPrice,
              klineRngMaxPrice: widget.klineState.klineRngMaxPrice,
              emaCurves: widget.klineState.emaCurves,
              crossLineFollowKlineIndex: widget.klineState.crossLineFollowKlineIndex,
              klineStep: widget.klineState.klineStep,
              klineWidth: widget.klineState.klineWidth,
              stockColors: widget.stockColors,
            ),
          ),
        ],
      ),
    );
  }

  // 绘制EMA曲线按钮组
  Widget _buildEmaCurveButtons(BuildContext context, Map<String, int> emaCurveMap) {
    List<Widget> widgets = [];
    for (final entry in emaCurveMap.entries) {
      Color emaColor = _getEmaColor(entry.value);
      TextButton button = TextButton(
        style: TextButton.styleFrom(foregroundColor: emaColor),
        onPressed: () => {},
        child: Text(entry.key),
      );
      widgets.add(button);
    }

    return Row(children: widgets);
  }

  // 获取EMA曲线颜色
  Color _getEmaColor(int period) {
    return switch (period) {
      5 => Colors.white,
      10 => const Color.fromARGB(255, 236, 9, 202),
      20 => const Color.fromARGB(255, 72, 105, 239),
      30 => const Color(0xFFFF9F1A),
      60 => const Color.fromARGB(255, 11, 180, 218),
      255 => const Color.fromARGB(255, 245, 16, 16),
      905 => const Color.fromARGB(255, 7, 131, 75),
      _ => Colors.purple,
    };
  }
}
