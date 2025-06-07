// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/indicators/macd_indicator.dart
// Purpose:     MACD share tech indicator
// Author:      songhuabiao
// Created:     2025-06-05 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/theme/stock_colors.dart';

class BollIndicator extends StatefulWidget {
  final KlineCtrlState klineCtrlState;
  final StockColors stockColors;
  const BollIndicator({super.key, required this.klineCtrlState, required this.stockColors});
  @override
  State<BollIndicator> createState() => _BollIndicatorState();
}

class _BollIndicatorState extends State<BollIndicator> {
  @override
  Widget build(BuildContext context) {
    KlineCtrlState state = widget.klineCtrlState;
    if (state.klines.isEmpty) {
      return SizedBox(height: state.indicatorChartHeight);
    }

    return SizedBox(
      width: state.klineCtrlWidth,
      height: state.indicatorChartHeight,
      child: CustomPaint(
        painter: _BollIndicatorPainter(
          boll: state.boll,
          klines: state.klines,
          klineRng: state.klineRng!,
          klineStep: state.klineStep,
          klineWidth: state.klineWidth,
          crossLineFollowKlineIndex: state.crossLineFollowKlineIndex,
          klineChartWidth: state.klineChartWidth,
          klineChartLeftMargin: state.klineChartLeftMargin,
          klineChartRightMargin: state.klineChartRightMargin,
          indicatorChartTitleBarHeight: state.indicatorChartTitleBarHeight,
        ),
      ),
    );
  }
}

class _BollIndicatorPainter extends CustomPainter {
  final Map<String, List<double>> boll;
  final List<UiKline> klines;
  final UiKlineRange klineRng;
  final int crossLineFollowKlineIndex;
  final double klineStep;
  final double klineWidth;
  final double klineChartWidth;
  final double klineChartLeftMargin;
  final double klineChartRightMargin;
  final double indicatorChartTitleBarHeight;
  final _bandPaint = Paint()..style = PaintingStyle.fill;
  final _linePaint = Paint()..style = PaintingStyle.stroke;

  _BollIndicatorPainter({
    required this.boll,
    required this.klines,
    required this.klineRng,
    required this.crossLineFollowKlineIndex,
    required this.klineStep,
    required this.klineWidth,
    required this.klineChartWidth,
    required this.klineChartLeftMargin,
    required this.klineChartRightMargin,
    required this.indicatorChartTitleBarHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (boll.isEmpty) return;

    // 绘制标题栏
    drawTitleBar(canvas, size);
    // 绘制成交额柱状图
    drawBollingerBands(canvas, size.height);

    // 绘制左边MACD指示面板
    // canvas.save();
    // canvas.translate(-2, 0);
    // drawKlinePane(
    //   type: KlinePaneType.amount,
    //   canvas: canvas,
    //   width: klineChartLeftMargin,
    //   height: size.height,
    //   reference: 0,
    //   min: 0,
    //   max: 0,
    //   nRows: 4,
    //   textAlign: TextAlign.right,
    //   fontSize: 11,
    //   offsetY: indicatorChartTitleBarHeight,
    // );
    // canvas.restore();

    // // 绘制右边MACD指示面板
    // canvas.save();
    // canvas.translate(klineChartLeftMargin + klineChartWidth + 2, 0);
    // drawKlinePane(
    //   type: KlinePaneType.amount,
    //   canvas: canvas,
    //   width: klineChartLeftMargin,
    //   height: size.height,
    //   reference: 0,
    //   min: 0,
    //   max: 0,
    //   nRows: 4,
    //   textAlign: TextAlign.left,
    //   fontSize: 11,
    //   offsetY: indicatorChartTitleBarHeight,
    // );
    // canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! _BollIndicatorPainter) return true;
    final old = oldDelegate;

    // 比较基础类型和引用
    if (old.klineStep != klineStep ||
        old.klineWidth != klineWidth ||
        old.klineChartWidth != klineChartWidth ||
        old.klineRng != klineRng ||
        old.klineChartLeftMargin != klineChartLeftMargin ||
        old.klineChartRightMargin != klineChartRightMargin) {
      return true;
    }

    // 深度比较列表内容（假设列表顺序和长度决定是否更新）
    if (old.boll.length != boll.length) {
      return true;
    }

    return false;
  }

  void drawTitleBar(Canvas canvas, Size size) {}

  void drawBollingerBands(Canvas canvas, double height) {
    // 参数安全校验
    final upperBand = boll['upper'] ?? [];
    final middleBand = boll['middle'] ?? [];
    final lowerBand = boll['lower'] ?? [];

    if (upperBand.isEmpty ||
        middleBand.isEmpty ||
        lowerBand.isEmpty ||
        klines.isEmpty ||
        upperBand.length != klines.length) {
      return;
    }

    // 计算有效绘制区间
    final startIdx = klineRng.begin.clamp(0, klines.length - 1).toInt();
    final endIdx = klineRng.end.clamp(0, klines.length - 1).toInt();
    if (startIdx > endIdx) return;

    // 动态计算Y轴范围
    final priceRange = _calculateBollingerRange(
      klines: klines,
      upperBand: upperBand,
      lowerBand: lowerBand,
      startIdx: startIdx,
      endIdx: endIdx,
    );
    final bodyHeight = height - indicatorChartTitleBarHeight;
    // 缩放因子
    final scaleY = bodyHeight / (priceRange.max - priceRange.min);

    // 绘制轨道区域
    canvas.save();
    canvas.translate(klineChartLeftMargin, indicatorChartTitleBarHeight);

    final bandPath =
        Path()..moveTo(0, bodyHeight - (upperBand[startIdx] - priceRange.min) * scaleY);
    double x = 0;
    for (int i = startIdx; i <= endIdx; i++) {
      bandPath.lineTo(x, bodyHeight - (upperBand[i] - priceRange.min) * scaleY);
      x += klineStep;
    }
    for (int i = endIdx; i >= startIdx; i--) {
      x -= klineStep;
      bandPath.lineTo(x, bodyHeight - (lowerBand[i] - priceRange.min) * scaleY);
    }
    bandPath.close();
    canvas.drawPath(
      bandPath,
      _bandPaint..color = const Color.fromARGB(255, 46, 197, 252).withOpacity(0.5),
    );

    // 绘制中线
    x = 0;
    final middlePath =
        Path()..moveTo(0, bodyHeight - (middleBand[startIdx] - priceRange.min) * scaleY);
    for (int i = startIdx; i <= endIdx; i++) {
      middlePath.lineTo(x, bodyHeight - (middleBand[i] - priceRange.min) * scaleY);
      x += klineStep;
    }
    canvas.drawPath(
      middlePath,
      _linePaint
        ..color = const Color.fromARGB(255, 201, 23, 23)
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }

  // 辅助函数：计算布林线绘制范围（包含价格和轨道线）
  ({double min, double max}) _calculateBollingerRange({
    required List<UiKline> klines,
    required List<double> upperBand,
    required List<double> lowerBand,
    required int startIdx,
    required int endIdx,
  }) {
    double minPrice = double.infinity;
    double maxPrice = -double.infinity;

    // 同时考虑收盘价和布林轨道边界
    for (int i = startIdx; i <= endIdx; i++) {
      final close = klines[i].priceClose;
      minPrice = min(minPrice, min(close, lowerBand[i]));
      maxPrice = max(maxPrice, max(close, upperBand[i]));
    }

    // 保证最小高度范围（避免除零和平坦线）
    if (maxPrice - minPrice < 10) {
      final center = (maxPrice + minPrice) / 2;
      return (min: center - 5, max: center + 5);
    }

    return (min: minPrice, max: maxPrice);
  }
}
