// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/indicators/minute_volume_indicator.dart
// Purpose:     minute volume indicator
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_chart_common.dart';
import 'package:irich/global/stock.dart';

class MinuteVolumeIndicator extends StatefulWidget {
  final KlineState klineState;
  const MinuteVolumeIndicator({super.key, required this.klineState});

  @override
  State<MinuteVolumeIndicator> createState() => _MinuteVolumeIndicatorState();
}

class _MinuteVolumeIndicatorState extends State<MinuteVolumeIndicator> {
  @override
  Widget build(BuildContext context) {
    KlineState state = widget.klineState;
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
          crossLineIndex: state.crossLineIndex,
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
  final int crossLineIndex;
  final KlineType klineType;
  late final double maxVolume;

  _MinuteVolumePainter({
    required this.klineChartLeftMargin,
    required this.klineChartWidth,
    required this.minuteKlines,
    required this.fiveDayMinuteKlines,
    required this.crossLineIndex,
    required this.klineType,
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
      nCols: 4,
      nBigRows: 0,
      nBigCols: 2,
      color: Colors.grey,
    );
    // 绘制十字线
    if (crossLineIndex != -1) {
      drawCrossLine(canvas, size);
    }
    canvas.restore();
    // 绘制左边指示面板
  }

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

    Paint greyPen = Paint()..color = Colors.grey;
    Paint redPen = Paint()..color = Colors.red;
    Paint greenPen = Paint()..color = Colors.green;

    for (int i = 1; i < totalLines; i++) {
      final x = i * barWidth;
      final y = height * (1 - klines[i].volume / BigInt.from(maxVolume));
      final h = height * klines[i].volume.toDouble() / maxVolume;
      if (klines[i].price > klines[i - 1].price) {
        canvas.drawLine(Offset(x, y), Offset(x, y + h), redPen);
      } else if (klines[i].price < klines[i - 1].price) {
        canvas.drawLine(Offset(x, y), Offset(x, y + h), greenPen);
      } else {
        canvas.drawLine(Offset(x, y), Offset(x, y + h), greyPen);
      }
    }
  }

  void drawCrossLine(Canvas canvas, Size size) {
    final maxLines = klineType == KlineType.minute ? 240 : 1200;
    final barWidth = size.width / maxLines;
    canvas.save();
    canvas.translate(klineChartLeftMargin, 0);
    drawVerticalLine(canvas: canvas, x: crossLineIndex * barWidth, yTop: 0, yBottom: size.height);
    canvas.restore();
  }

  // String _formatVolume(double volume) {
  //   if (volume >= 100000000) {
  //     return '${(volume / 100000000).toStringAsFixed(2)}亿';
  //   } else if (volume >= 10000) {
  //     return '${(volume / 10000).toStringAsFixed(2)}万';
  //   }
  //   return volume.toStringAsFixed(0);
  // }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
