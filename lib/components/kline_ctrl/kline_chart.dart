// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/kline_ctrl/KlineChart.dart
// Purpose:     kline chart
// Author:      songhuabiao
// Created:     2025-05-22 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/widgets.dart';
import 'package:irich/components/kline_ctrl/kline_chart_common.dart';
import 'package:irich/components/kline_ctrl/kline_chart_painter.dart';

class KlineChart extends StatefulWidget {
  final KlineState klineState;
  const KlineChart({super.key, required this.klineState});

  @override
  State<KlineChart> createState() => _KlineChartState();
}

class _KlineChartState extends State<KlineChart> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width:
          widget.klineState.klineChartWidth +
          widget.klineState.klineChartLeftMargin +
          widget.klineState.klineChartRightMargin,
      height: widget.klineState.klineChartHeight,
      color: const Color(0xFF1E1E1E),
      child: CustomPaint(
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
          emaCurves: widget.klineState.emaCurves,
          crossLineIndex: widget.klineState.crossLineIndex,
          klineStep: widget.klineState.klineStep,
          klineWidth: widget.klineState.klineWidth,
        ),
      ),
    );
  }
}
