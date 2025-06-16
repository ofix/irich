// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/indicators/macd_indicator.dart
// Purpose:     MACD share tech indicator
// Author:      songhuabiao
// Created:     2025-06-05 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/theme/stock_colors.dart';

class MacdIndicator extends StatefulWidget {
  final KlineCtrlState klineCtrlState;
  final StockColors stockColors;
  const MacdIndicator({super.key, required this.klineCtrlState, required this.stockColors});
  @override
  State<MacdIndicator> createState() => _MacdIndicatorState();
}

class _MacdIndicatorState extends State<MacdIndicator> {
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
        painter: _MacdIndicatorPainter(
          macd: state.macd,
          klineRng: state.klineRng,
          klineStep: state.klineStep,
          klineWidth: state.klineWidth,
          crossLineFollowKlineIndex: state.crossLineFollowKlineIndex,
          klineChartWidth: state.klineChartWidth,
          klineChartLeftMargin: state.klineChartLeftMargin,
          klineChartRightMargin: state.klineChartRightMargin,
          indicatorChartTitleBarHeight: state.indicatorChartTitleBarHeight,
          stockColors: widget.stockColors,
        ),
      ),
    );
  }
}

class _MacdIndicatorPainter extends CustomPainter {
  final Map<String, List<double>> macd;
  final UiKlineRange klineRng;
  final int crossLineFollowKlineIndex;
  final double klineStep;
  final double klineWidth;
  final double klineChartWidth;
  final double klineChartLeftMargin;
  final double klineChartRightMargin;
  final double indicatorChartTitleBarHeight;
  final StockColors stockColors;

  _MacdIndicatorPainter({
    required this.macd,
    required this.klineRng,
    required this.crossLineFollowKlineIndex,
    required this.klineStep,
    required this.klineWidth,
    required this.klineChartWidth,
    required this.klineChartLeftMargin,
    required this.klineChartRightMargin,
    required this.indicatorChartTitleBarHeight,
    required this.stockColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (macd.isEmpty) return;

    // 绘制标题栏
    drawTitleBar(canvas, size);
    // 绘制成交额柱状图
    drawMACD(canvas, size.height);

    // // 绘制左边MACD指示面板
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
    if (oldDelegate is! _MacdIndicatorPainter) return true;
    final old = oldDelegate;

    // 比较基础类型和引用
    if (old.klineStep != klineStep ||
        old.klineWidth != klineWidth ||
        old.klineChartWidth != klineChartWidth ||
        old.klineRng != klineRng ||
        old.stockColors != stockColors ||
        old.klineChartLeftMargin != klineChartLeftMargin ||
        old.klineChartRightMargin != klineChartRightMargin) {
      return true;
    }

    // 深度比较列表内容（假设列表顺序和长度决定是否更新）
    if (old.macd.length != macd.length) {
      return true;
    }

    return false;
  }

  void drawTitleBar(Canvas canvas, Size size) {
    final macdValue = macd['MACD']?.last.toStringAsFixed(2);
    final diffValue = macd['DIF']?.last.toStringAsFixed(2);
    final deaValue = macd['DEA']?.last.toStringAsFixed(2);
    List<ColorText> words = [
      ColorText('MACD(12,26,9)', Colors.grey),
      ColorText('MACD: $macdValue', stockColors.macdRedBar),
      ColorText('DIFF: $diffValue', stockColors.macdDif),
      ColorText('DEA: $deaValue', stockColors.macdDea),
    ];

    drawIndicatorTitleBar(
      canvas: canvas,
      words: words,
      width: size.width,
      offset: Offset(4, 0),
      height: indicatorChartTitleBarHeight,
    );
  }

  void drawMACD(Canvas canvas, double height) {
    final dif = macd['DIF'] ?? [];
    final dea = macd['DEA'] ?? [];
    final macdValues = macd['MACD'] ?? [];
    if (dif.isEmpty || dea.isEmpty || macdValues.isEmpty) return;

    final bodyHeight = height - indicatorChartTitleBarHeight;
    canvas.save();
    canvas.translate(klineChartLeftMargin, indicatorChartTitleBarHeight);
    // 计算实际需要绘制的数据范围
    final size = Size(klineChartWidth, bodyHeight);
    double max = double.negativeInfinity;
    double min = double.infinity;
    int startIndex = klineRng.begin;
    int endIndex = klineRng.end;
    for (int i = startIndex; i < endIndex; i++) {
      if (dif[i] < min) min = dif[i];
      if (dea[i] < min) min = dea[i];
      if (macdValues[i] < min) min = macdValues[i];

      if (dif[i] > max) max = dif[i];
      if (dea[i] > max) max = dea[i];
      if (macdValues[i] > max) max = macdValues[i];
    }

    // 绘制DIF线
    _drawLine(
      canvas: canvas,
      size: size,
      data: dif,
      startIdx: startIndex,
      endIdx: endIndex,
      min: min,
      max: max,
      color: stockColors.macdDif,
    );

    // 绘制DEA线
    _drawLine(
      canvas: canvas,
      size: size,
      data: dea,
      startIdx: startIndex,
      endIdx: endIndex,
      min: min,
      max: max,
      color: stockColors.macdDea,
    );

    // 绘制MACD柱状图
    _drawMacdBars(
      canvas: canvas,
      size: size,
      data: macdValues,
      startIdx: startIndex,
      endIdx: endIndex,
      min: min,
      max: max,
      positiveColor: stockColors.macdRedBar,
      negativeColor: stockColors.macdGreenBar,
    );
    canvas.restore();
  }

  void _drawLine({
    required Canvas canvas,
    required Size size,
    required List<double> data,

    required int startIdx,
    required int endIdx,
    required double min,
    required double max,
    required Color color,
  }) {
    if (data.isEmpty) return;

    final path = Path();
    final height = size.height;

    final range = max - min;
    final scaleY = height / (range == 0 ? 1 : range);

    path.moveTo(0, height - (data[startIdx] - min) * scaleY);
    for (int i = startIdx + 1; i <= endIdx; i++) {
      final x = (i - startIdx) * klineStep;
      final y = height - (data[i] - min) * scaleY;
      path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawMacdBars({
    required Canvas canvas,
    required Size size,
    required List<double> data,
    required int startIdx,
    required int endIdx,
    required double min,
    required double max,
    required Color positiveColor,
    required Color negativeColor,
  }) {
    // 参数安全检查
    if (data.isEmpty || startIdx >= data.length || endIdx >= data.length || startIdx > endIdx) {
      return;
    }
    final range = max - min;
    final yScale = size.height / range;
    final baseY = size.height * (1 + min / range);

    double zeroY = size.height * (1 - (0 - min) / range);
    final paintPositive =
        Paint()
          ..color = positiveColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    final paintNegative =
        Paint()
          ..color = negativeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    double x = klineWidth / 2;
    for (int i = startIdx; i <= endIdx; i++) {
      final value = data[i];
      if (value == 0) {
        x += klineStep;
        continue;
      }

      final y = baseY - value * yScale;

      // 绘制从零线到值的线段
      canvas.drawLine(Offset(x, zeroY), Offset(x, y), value > 0 ? paintPositive : paintNegative);

      x += klineStep;
    }
  }
}
