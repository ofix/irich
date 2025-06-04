// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/indicators/minute_amount_indicator.dart
// Purpose:     minute_amount_indicator
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_chart_common.dart';
import 'package:irich/global/stock.dart';

class MinuteAmountIndicator extends StatefulWidget {
  final KlineState klineState;
  const MinuteAmountIndicator({super.key, required this.klineState});

  @override
  State<MinuteAmountIndicator> createState() => _MinuteAmountIndicatorState();
}

class _MinuteAmountIndicatorState extends State<MinuteAmountIndicator> {
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
          minuteKlines: state.minuteKlines,
          fiveDayMinuteKlines: state.fiveDayMinuteKlines,
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
  late final double maxAmount;

  _MinuteVolumePainter({
    required this.klineChartLeftMargin,
    required this.klineChartWidth,
    required this.minuteKlines,
    required this.fiveDayMinuteKlines,
    required this.crossLineIndex,
    required this.klineType,
  }) {
    maxAmount = calcMaxAmount().toDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(klineChartLeftMargin, 0);
    // 绘制成交量柱状图
    if (klineType == KlineType.minute) {
      _drawVolumeBars(canvas, size.height, minuteKlines);
    } else {
      _drawVolumeBars(canvas, size.height, fiveDayMinuteKlines);
    }
    // 绘制边框和网格
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
      _drawCrossLine(canvas, size.height);
    }
    canvas.restore();
  }

  double calcMaxAmount() {
    if (klineType == KlineType.minute) {
      return minuteKlines.map((k) => k.amount).reduce((a, b) => a > b ? a : b);
    } else {
      return fiveDayMinuteKlines.map((k) => k.amount).reduce((a, b) => a > b ? a : b);
    }
  }

  void _drawVolumeBars(Canvas canvas, double height, List<MinuteKline> klines) {
    final maxKlines = klineType == KlineType.minute ? 240 : 1200;
    final barStep = klineChartWidth / maxKlines;
    final totalLines =
        klineType == KlineType.minute ? klines.length.clamp(0, 240) : klines.length.clamp(0, 1200);

    Paint greyPen = Paint()..color = Colors.grey;
    Paint redPen = Paint()..color = Colors.red;
    Paint greenPen = Paint()..color = Colors.green;
    for (int i = 1; i < totalLines; i++) {
      final x = i * barStep;
      final y = height * (1 - klines[i].volume / BigInt.from(maxAmount));
      final h = height * klines[i].volume.toDouble() / maxAmount;
      if (klines[i].price > klines[i - 1].price) {
        canvas.drawLine(Offset(x, y), Offset(x, y + h), redPen);
      } else if (klines[i].price < klines[i - 1].price) {
        canvas.drawLine(Offset(x, y), Offset(x, y + h), greenPen);
      } else {
        canvas.drawLine(Offset(x, y), Offset(x, y + h), greyPen);
      }
    }
  }

  void _drawGridAndBorder(Canvas canvas, double height) {
    // 绘制边框
    final borderPaint =
        Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    canvas.drawRect(Rect.fromLTWH(0, 0, klineChartWidth, height), borderPaint);

    // 绘制水平网格线
    final hRow = height / 4;
    final dotPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    for (int i = 1; i <= 3; i++) {
      final y = i * hRow;
      canvas.drawLine(Offset(0, y), Offset(klineChartWidth, y), dotPaint);
    }

    // 绘制垂直网格线
    final nCols = klineType == KlineType.minute ? 8 : 20;
    final wCol = (klineChartWidth) / nCols;

    for (int i = 1; i < nCols; i++) {
      if (i % 4 == 0) continue;
      final x = i * wCol;
      canvas.drawLine(Offset(x, 0), Offset(x, height), dotPaint);
    }

    // 绘制粗垂直网格线
    final solidPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    for (int i = 4; i < nCols; i += 4) {
      final x = i * wCol;
      canvas.drawLine(Offset(x, 0), Offset(x, height), solidPaint);
    }

    // 绘制刻度标签
    final textStyle = TextStyle(color: Colors.grey, fontSize: 10);
    final rowVolume = maxAmount / 4;

    for (int i = 0; i <= 4; i++) {
      final label = _formatVolume(maxAmount - rowVolume * i);
      final y = i * hRow;
      // 左侧标签
      _drawLabel(canvas, label, Offset(-4, y), textStyle, TextAlign.right);
      // 右侧标签
      _drawLabel(canvas, label, Offset(klineChartWidth + 4, y), textStyle, TextAlign.left);
    }
  }

  void _drawCrossLine(Canvas canvas, double height) {
    final maxLines = klineType == KlineType.minute ? 240 : 1200;
    final barWidth = klineChartWidth / maxLines;

    final x = crossLineIndex * barWidth;

    final crossPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..strokeWidth = 0.5;

    // 垂直线
    canvas.drawLine(Offset(x, 0), Offset(x, height), crossPaint);
  }

  // 绘制右侧标签
  void _drawLabel(Canvas canvas, String text, Offset position, TextStyle style, TextAlign align) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();

    textPainter.paint(canvas, position - Offset(0, textPainter.height / 2));
  }

  String _formatVolume(double volume) {
    if (volume >= 100000000) {
      return '${(volume / 100000000).toStringAsFixed(2)}亿';
    } else if (volume >= 10000) {
      return '${(volume / 10000).toStringAsFixed(2)}万';
    }
    return volume.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
