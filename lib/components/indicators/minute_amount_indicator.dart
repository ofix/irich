// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/indicators/minute_amount_indicator.dart
// Purpose:     minute_amount_indicator
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/theme/stock_colors.dart';

class MinuteAmountIndicator extends StatefulWidget {
  final KlineState klineState;
  final StockColors stockColors;
  const MinuteAmountIndicator({super.key, required this.klineState, required this.stockColors});

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
          crossLineFollowKlineIndex: state.crossLineFollowKlineIndex,
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
  late final double maxAmount;

  _MinuteVolumePainter({
    required this.klineChartLeftMargin,
    required this.klineChartWidth,
    required this.minuteKlines,
    required this.fiveDayMinuteKlines,
    required this.crossLineFollowKlineIndex,
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
      drawAmountBars(canvas, size.height, minuteKlines);
    } else {
      drawAmountBars(canvas, size.height, fiveDayMinuteKlines);
    }
    // 绘制边框和网格
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

    // 绘制左边成交额指示面板
    canvas.save();
    canvas.translate(-2, 0);
    drawKlinePane(
      type: KlinePaneType.minuteAmount,
      canvas: canvas,
      width: klineChartLeftMargin,
      height: size.height,
      reference: 0,
      min: 0,
      max: maxAmount,
      nRows: 4,
      textAlign: TextAlign.right,
      fontSize: 11,
    );
    canvas.restore();

    // 绘制右边成交额指示面板
    canvas.save();
    canvas.translate(klineChartLeftMargin + klineChartWidth + 2, 0);
    drawKlinePane(
      type: KlinePaneType.minuteAmount,
      canvas: canvas,
      width: klineChartLeftMargin,
      height: size.height,
      reference: 0,
      min: 0,
      max: maxAmount,
      nRows: 4,
      textAlign: TextAlign.left,
      fontSize: 11,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  double calcMaxAmount() {
    if (klineType == KlineType.minute) {
      return minuteKlines.map((k) => k.amount).reduce((a, b) => a > b ? a : b);
    } else {
      return fiveDayMinuteKlines.map((k) => k.amount).reduce((a, b) => a > b ? a : b);
    }
  }

  void drawAmountBars(Canvas canvas, double height, List<MinuteKline> klines) {
    final maxKlines = klineType == KlineType.minute ? 240 : 1200;
    final barStep = klineChartWidth / maxKlines;
    final totalLines =
        klineType == KlineType.minute ? klines.length.clamp(0, 240) : klines.length.clamp(0, 1200);

    Paint whitePen = Paint()..color = Colors.white;
    Paint redPen = Paint()..color = Colors.red;
    Paint greenPen = Paint()..color = Colors.green;
    for (int i = 1; i < totalLines; i++) {
      final x = i * barStep;
      final y = height * (1 - klines[i].amount / maxAmount);
      final h = height * klines[i].amount.toDouble() / maxAmount;
      if (klines[i].price > klines[i - 1].price) {
        canvas.drawLine(Offset(x, y), Offset(x, y + h), redPen);
      } else if (klines[i].price < klines[i - 1].price) {
        canvas.drawLine(Offset(x, y), Offset(x, y + h), greenPen);
      } else {
        canvas.drawLine(Offset(x, y), Offset(x, y + h), whitePen);
      }
    }
  }
}
