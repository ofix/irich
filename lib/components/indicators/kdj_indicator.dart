// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/indicators/kdj_indicator.dart
// Purpose:     KDJ share tech indicator
// Author:      songhuabiao
// Created:     2025-06-05 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_chart_common.dart';
import 'package:irich/global/stock.dart';

class KdjIndicator extends StatefulWidget {
  final KlineState klineState;
  const KdjIndicator({super.key, required this.klineState});
  @override
  State<KdjIndicator> createState() => _KdjIndicatorState();
}

class _KdjIndicatorState extends State<KdjIndicator> {
  @override
  Widget build(BuildContext context) {
    KlineState state = widget.klineState;
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
          crossLineIndex: state.crossLineIndex,
          klineChartWidth: state.klineChartWidth,
          klineChartLeftMargin: state.klineChartLeftMargin,
          klineChartRightMargin: state.klineChartRightMargin,
        ),
      ),
    );
  }
}

class _KdjIndicatorPainter extends CustomPainter {
  final Map<String, List<double>> kdj;
  final UiKlineRange klineRng;
  final int crossLineIndex;
  final double klineStep;
  final double klineWidth;
  final double klineChartWidth;
  final double klineChartLeftMargin;
  final double klineChartRightMargin;
  final double titleHeight = 20.0;

  _KdjIndicatorPainter({
    required this.kdj,
    required this.klineRng,
    required this.crossLineIndex,
    required this.klineStep,
    required this.klineWidth,
    required this.klineChartWidth,
    required this.klineChartLeftMargin,
    required this.klineChartRightMargin,
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
    //   offsetY: titleHeight,
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
    //   offsetY: titleHeight,
    // );
    // canvas.restore();
  }

  void drawTitleBar(Canvas canvas, Size size) {
    final textStyle = TextStyle(color: Colors.white, fontSize: 12);

    // 绘制标题背景
    final bgPaint =
        Paint()
          ..color = const Color(0xFF252525)
          ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, titleHeight), bgPaint);

    // 绘制标题文本
    final textPainter = TextPainter(
      text: TextSpan(text: '成交额', style: textStyle.copyWith(color: Colors.grey)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(4, 4));

    // 绘制昨日成交额
    final yesterdayText = TextPainter(
      text: TextSpan(
        text: '昨: ${formatAmount(kdj.isNotEmpty ? 0 : 0)}',
        style: textStyle.copyWith(color: const Color.fromARGB(255, 237, 130, 8)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    yesterdayText.paint(canvas, Offset(textPainter.width + 12, 4));

    // 绘制今日成交额
    final todayText = TextPainter(
      text: TextSpan(
        text: '今: ${formatAmount(kdj.isNotEmpty ? 0 : 0)}',
        style: textStyle.copyWith(color: Colors.red),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    todayText.paint(canvas, Offset(textPainter.width + yesterdayText.width + 24, 4));
  }

  void drawKdj(Canvas canvas, double height) {
    final bodyHeight = height - titleHeight;
    // 参数安全校验
    if (kdj.isEmpty) {
      return;
    }

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
    final startIdx = klineRng.begin.clamp(0, kLine.length - 1).toInt();
    final endIdx = klineRng.end.clamp(0, kLine.length - 1).toInt();
    if (startIdx > endIdx) return;

    // KDJ固定范围 [0,100]，无需动态计算Y轴
    const kdjMin = 0.0;
    const kdjMax = 100.0;
    final scaleY = bodyHeight / (kdjMax - kdjMin);

    // 创建画笔
    final kPaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    final dPaint =
        Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    final jPaint =
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    // 绘制三条曲线
    void drawLine(List<double> data, Paint paint) {
      final path = Path();
      double x = 0;
      path.moveTo(x, bodyHeight - (data[startIdx] - kdjMin) * scaleY);

      for (int i = startIdx; i <= endIdx; i++) {
        path.lineTo(x, bodyHeight - (data[i] - kdjMin) * scaleY);
        x += klineStep;
      }
      canvas.drawPath(path, paint);
    }

    canvas.save();
    canvas.translate(klineChartLeftMargin, titleHeight);
    drawLine(kLine, kPaint); // K线
    drawLine(dLine, dPaint); // D线
    drawLine(jLine, jPaint); // J线

    // 可选：绘制参考线（20/50/80）
    final refPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;

    for (final refValue in [20.0, 50.0, 80.0]) {
      final y = bodyHeight - (refValue - kdjMin) * scaleY;
      canvas.drawLine(Offset(0, y), Offset(klineStep * (endIdx - startIdx), y), refPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
