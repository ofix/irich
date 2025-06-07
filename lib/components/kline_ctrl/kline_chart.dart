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
import 'package:irich/components/rich_checkbox_button_group.dart';
import 'package:irich/theme/stock_colors.dart';

class KlineChart extends StatefulWidget {
  final KlineCtrlState klineCtrlState;
  final StockColors stockColors;
  const KlineChart({super.key, required this.klineCtrlState, required this.stockColors});

  @override
  State<KlineChart> createState() => _KlineChartState();
}

class _KlineChartState extends State<KlineChart> {
  // EMA日K线
  @override
  Widget build(BuildContext context) {
    final state = widget.klineCtrlState;
    return Container(
      width: state.klineCtrlWidth,
      height: state.klineType.isMinuteType ? state.klineChartHeight : state.klineChartHeight + 22,
      color: const Color.fromARGB(255, 28, 29, 33),
      child: Stack(
        children: [
          if (!state.klineType.isMinuteType)
            Positioned(top: -4, child: _buildEmaCurveButtons(context, state.emaCurveSettings)),
          Positioned(
            top: state.klineType.isMinuteType ? 0 : 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // 强制左对齐
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size(state.klineCtrlWidth, state.klineChartHeight),
                    painter: KlinePainter(
                      share: state.share,
                      klineChartWidth: state.klineChartWidth,
                      klineChartHeight: state.klineChartHeight,
                      klineChartLeftMargin: state.klineChartLeftMargin,
                      klineChartRightMargin: state.klineChartRightMargin,
                      klineType: state.klineType,
                      klines: state.klines,
                      minuteKlines: state.minuteKlines,
                      fiveDayMinuteKlines: state.fiveDayMinuteKlines,
                      klineRngBegin: state.klineRng!.begin,
                      klineRngEnd: state.klineRng!.end,
                      klineRngMinPrice: state.klineRngMinPrice,
                      klineRngMaxPrice: state.klineRngMaxPrice,
                      emaCurves: state.emaCurves,
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

  // 绘制EMA曲线按钮组
  Widget _buildEmaCurveButtons(BuildContext context, List<EmaCurveSetting> emaCurveSettings) {
    Map<String, CheckBoxOption> options = {};
    for (final emaCurveSetting in emaCurveSettings) {
      String key = 'EMA${emaCurveSetting.period}';
      options[key] = CheckBoxOption(
        selectedColor: emaCurveSetting.color,
        selected: emaCurveSetting.visible,
      );
    }
    return RichCheckboxButtonGroup(options: options);
  }
}
