// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/indicators/minute_volume_indicator.dart
// Purpose:     minute volume indicator
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/theme/stock_colors.dart';

class MinuteVolumeIndicator extends StatefulWidget {
  final KlineCtrlState klineCtrlState;
  final StockColors stockColors;
  const MinuteVolumeIndicator({super.key, required this.klineCtrlState, required this.stockColors});

  @override
  State<MinuteVolumeIndicator> createState() => _MinuteVolumeIndicatorState();
}

class _MinuteVolumeIndicatorState extends State<MinuteVolumeIndicator> {
  @override
  Widget build(BuildContext context) {
    KlineCtrlState state = widget.klineCtrlState;
    if (state.klineType == KlineType.minute) {
      if (state.minuteKlines.isEmpty) {
        return SizedBox(height: state.indicatorChartHeight);
      }
    } else {
      if (state.fiveDayMinuteKlines.isEmpty) {
        return SizedBox(height: state.indicatorChartHeight);
      }
    }

    return SizedBox(
      width: state.klineChartWidth + state.klineChartLeftMargin + state.klineChartRightMargin,
      height: state.indicatorChartHeight,
      child: CustomPaint(
        painter: _MinuteVolumePainter(
          klineChartLeftMargin: state.klineChartLeftMargin,
          klineChartWidth: state.klineChartWidth,
          fiveDayMinuteKlines: state.fiveDayMinuteKlines,
          minuteKlines: state.minuteKlines,
          klineType: state.klineType,
          crossLineFollowKlineIndex: state.crossLineFollowKlineIndex,
          stockColors: widget.stockColors,
        ),
      ),
    );
  }
}

class _MinuteVolumePainter extends CustomPainter {
  final double klineChartLeftMargin;
  final double klineChartWidth;
  final List<MinuteKline> minuteKlines;
  final List<MinuteKline> fiveDayMinuteKlines;
  final int crossLineFollowKlineIndex;
  final KlineType klineType;
  late final double maxVolume;
  final StockColors stockColors;
  _MinuteVolumePainter({
    required this.klineChartLeftMargin,
    required this.klineChartWidth,
    required this.minuteKlines,
    required this.fiveDayMinuteKlines,
    required this.crossLineFollowKlineIndex,
    required this.klineType,
    required this.stockColors,
  }) {
    maxVolume = _calcMaxVolume().toDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制成交量柱状图
    canvas.save();
    canvas.translate(klineChartLeftMargin, 0);
    if (klineType == KlineType.minute) {
      drawVolumeBars(canvas, size.height, minuteKlines);
    } else {
      drawVolumeBars(canvas, size.height, fiveDayMinuteKlines);
    }
    // 绘制分时网格
    drawGrid(
      canvas: canvas,
      width: klineChartWidth,
      height: size.height,
      nRows: 4,
      nCols: 8,
      nBigRows: 0,
      nBigCols: 0,
      color: Colors.grey,
    );
    canvas.restore();
    // 绘制左边成交量指示面板
    canvas.save();
    canvas.translate(-2, 0);
    drawKlinePane(
      type: KlinePaneType.minuteVolume,
      canvas: canvas,
      width: klineChartLeftMargin,
      height: size.height,
      reference: 0,
      min: 0,
      max: maxVolume,
      nRows: 4,
      textAlign: TextAlign.right,
      fontSize: 11,
    );
    canvas.restore();

    // 绘制右边成交量指示面板
    canvas.save();
    canvas.translate(klineChartLeftMargin + klineChartWidth + 2, 0);
    drawKlinePane(
      type: KlinePaneType.minuteVolume,
      canvas: canvas,
      width: klineChartLeftMargin,
      height: size.height,
      reference: 0,
      min: 0,
      max: maxVolume,
      nRows: 4,
      textAlign: TextAlign.left,
      fontSize: 11,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  BigInt _calcMaxVolume() {
    if (klineType == KlineType.minute) {
      return minuteKlines.map((k) => k.volume).reduce((a, b) => a > b ? a : b);
    } else {
      return fiveDayMinuteKlines.map((k) => k.volume).reduce((a, b) => a > b ? a : b);
    }
  }

  void drawVolumeBars(Canvas canvas, double height, List<MinuteKline> klines) {
    final maxKlines = klineType == KlineType.minute ? 240 : 1200;
    final barWidth = klineChartWidth / maxKlines;
    final totalLines =
        klineType == KlineType.minute ? klines.length.clamp(0, 240) : klines.length.clamp(0, 1200);

    Paint pen = Paint()..color = const Color.fromARGB(255, 136, 211, 251);
    for (int i = 1; i < totalLines; i++) {
      final x = i * barWidth;
      final y = height * (1 - klines[i].volume / BigInt.from(maxVolume));
      final h = height * klines[i].volume.toDouble() / maxVolume;
      canvas.drawLine(Offset(x, y), Offset(x, y + h), pen);
    }
  }
}
