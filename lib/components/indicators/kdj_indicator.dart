// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/indicators/kdj_indicator.dart
// Purpose:     KDJ share tech indicator
// Author:      songhuabiao
// Created:     2025-06-05 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/theme/stock_colors.dart';

class KdjIndicator extends StatefulWidget {
  final KlineCtrlState klineCtrlState;
  final StockColors stockColors;
  const KdjIndicator({super.key, required this.klineCtrlState, required this.stockColors});
  @override
  State<KdjIndicator> createState() => _KdjIndicatorState();
}

class _KdjIndicatorState extends State<KdjIndicator> {
  @override
  Widget build(BuildContext context) {
    KlineCtrlState state = widget.klineCtrlState;
    if (state.klines.isEmpty) {
      return SizedBox(height: state.indicatorChartHeight);
    }

    return SizedBox(
      width: state.klineChartWidth + state.klineChartLeftMargin + state.klineChartRightMargin,
      height: state.indicatorChartHeight,
      child: CustomPaint(
        painter: _KdjIndicatorPainter(
          kdj: state.kdj,
          klineRng: state.klineRng!,
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

class _KdjIndicatorPainter extends CustomPainter {
  final Map<String, List<double>> kdj;
  final UiKlineRange klineRng;
  final int crossLineFollowKlineIndex;
  final double klineStep;
  final double klineWidth;
  final double klineChartWidth;
  final double klineChartLeftMargin;
  final double klineChartRightMargin;
  final double indicatorChartTitleBarHeight;
  final StockColors stockColors;

  _KdjIndicatorPainter({
    required this.kdj,
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
    if (kdj.isEmpty) return;

    // 绘制标题栏
    drawTitleBar(canvas, size);
    // 绘制成交额柱状图
    drawKdj(canvas, size.height);

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
    if (oldDelegate is! _KdjIndicatorPainter) return true;
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
    if (old.kdj.length != kdj.length) {
      return true;
    }

    return false;
  }

  void drawTitleBar(Canvas canvas, Size size) {
    final k = kdj['K']?.last.toStringAsFixed(2);
    final d = kdj['D']?.last.toStringAsFixed(2);
    final j = kdj['J']?.last.toStringAsFixed(2);
    List<ColorText> words = [
      ColorText('KDJ(9,3,3)', Colors.grey),
      ColorText('K: $k', stockColors.kdjK),
      ColorText('D: $d', stockColors.kdjD),
      ColorText('J: $j', stockColors.kdjJ),
    ];

    drawIndicatorTitleBar(
      canvas: canvas,
      words: words,
      width: size.width,
      offset: Offset(4, 0),
      height: indicatorChartTitleBarHeight,
    );
  }

  void drawKdj(Canvas canvas, double height) {
    // 参数安全校验
    if (kdj.isEmpty) {
      return;
    }
    final bodyHeight = height - indicatorChartTitleBarHeight;

    final kLine = kdj['K'] ?? [];
    final dLine = kdj['D'] ?? [];
    final jLine = kdj['J'] ?? [];

    if (kLine.isEmpty ||
        dLine.isEmpty ||
        jLine.isEmpty ||
        kLine.length != dLine.length ||
        dLine.length != jLine.length) {
      return;
    }

    // 计算有效绘制区间
    final startIndex = klineRng.begin;
    final endIndex = klineRng.end;
    double min = double.infinity;
    double max = double.negativeInfinity;

    // KDJ固定范围 [0,100]，无需动态计算Y轴
    for (int i = startIndex; i < endIndex; i++) {
      if (kLine[i] < min) min = kLine[i];
      if (dLine[i] < min) min = dLine[i];
      if (jLine[i] < min) min = jLine[i];

      if (kLine[i] > max) max = kLine[i];
      if (dLine[i] > max) max = dLine[i];
      if (jLine[i] > max) max = jLine[i];
    }

    final scaleY = bodyHeight / (max - min);

    // 创建画笔
    final kPaint =
        Paint()
          ..color = stockColors.kdjK
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    final dPaint =
        Paint()
          ..color = stockColors.kdjD
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    final jPaint =
        Paint()
          ..color = stockColors.kdjJ
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    // 绘制三条曲线
    void drawLine(List<double> data, Paint paint) {
      final path = Path();
      double x = 0;
      path.moveTo(x, bodyHeight - (data[startIndex] - min) * scaleY);

      for (int i = startIndex + 1; i <= endIndex; i++) {
        path.lineTo(x, bodyHeight - (data[i] - min) * scaleY);
        x += klineStep;
      }
      canvas.drawPath(path, paint);
    }

    canvas.save();
    canvas.translate(klineChartLeftMargin, indicatorChartTitleBarHeight);
    drawLine(kLine, kPaint); // K线
    drawLine(dLine, dPaint); // D线
    drawLine(jLine, jPaint); // J线

    // 可选：绘制参考线（20/50/80）
    // final refPaint =
    //     Paint()
    //       ..color = Colors.grey.withOpacity(0.5)
    //       ..style = PaintingStyle.stroke
    //       ..strokeWidth = 0.8;

    // for (final refValue in [20.0, 50.0, 80.0]) {
    //   final y = bodyHeight - (refValue - kdjMin) * scaleY;
    //   canvas.drawLine(Offset(0, y), Offset(klineStep * (endIdx - startIdx), y), refPaint);
    // }

    canvas.restore();
  }
}
