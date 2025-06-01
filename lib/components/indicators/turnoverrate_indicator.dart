// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/indicators/turnoverrate indicator.dart
// Purpose:     turnoverrate indicator
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_ctrl.dart';
import 'package:irich/global/stock.dart';

class TurnoverRateIndicator extends StatefulWidget {
  final KlineState klineState;
  const TurnoverRateIndicator({super.key, required this.klineState});

  @override
  State<TurnoverRateIndicator> createState() => _TurnoverRateIndicatorState();
}

class _TurnoverRateIndicatorState extends State<TurnoverRateIndicator> {
  @override
  Widget build(BuildContext context) {
    KlineState state = widget.klineState;
    if (state.klines.isEmpty) {
      return SizedBox(height: state.indicatorChartHeight);
    }

    return SizedBox(
      width: state.width,
      height: state.indicatorChartHeight,
      child: CustomPaint(
        painter: _TurnoverRatePainter(
          klines: state.klines,
          klineRng: state.klineRng!,
          crossLineIndex: state.crossLineIndex,
          klineWidth: state.klineWidth,
          klineInnerWidth: state.klineInnerWidth,
          isUpList: _getIsUpList(state.klines),
        ),
      ),
    );
  }

  List<bool> _getIsUpList(List<UiKline> klines) {
    return klines.map((k) => k.priceClose >= k.priceOpen).toList();
  }
}

class _TurnoverRatePainter extends CustomPainter {
  final List<UiKline> klines;
  final UiKlineRange klineRng;
  final int crossLineIndex;
  final double klineWidth;
  final double klineInnerWidth;
  final List<bool> isUpList;

  _TurnoverRatePainter({
    required this.klines,
    required this.klineRng,
    required this.crossLineIndex,
    required this.klineWidth,
    required this.klineInnerWidth,
    required this.isUpList,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (klines.isEmpty) return;
    // 绘制标题栏
    _drawTitleBar(canvas, size);
    // 绘制换手率柱状图
    _drawTurnoverRateBars(canvas, size);
    // 绘制十字线
    if (crossLineIndex != -1) {
      _drawCrossLine(canvas, size);
    }
  }

  void _drawTitleBar(Canvas canvas, Size size) {
    const titleHeight = 20.0;
    final textStyle = TextStyle(color: Colors.white, fontSize: 12);

    // 绘制标题背景
    final bgPaint =
        Paint()
          ..color = const Color(0xFF252525)
          ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, titleHeight), bgPaint);

    // 绘制标题文本
    final textPainter = TextPainter(
      text: TextSpan(text: '换手率', style: textStyle.copyWith(color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(4, 4));

    // 绘制昨日换手率
    final yesterdayText = TextPainter(
      text: TextSpan(
        text: '昨: ${_formatRate(klines.isNotEmpty ? klines[0].turnoverRate : 0)}',
        style: textStyle.copyWith(color: Colors.grey),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    yesterdayText.paint(canvas, Offset(textPainter.width + 12, 4));

    // 绘制今日换手率
    final todayText = TextPainter(
      text: TextSpan(
        text: '今: ${_formatRate(klines.isNotEmpty ? klines.last.turnoverRate : 0)}',
        style: textStyle.copyWith(color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    todayText.paint(canvas, Offset(textPainter.width + yesterdayText.width + 24, 4));
  }

  void _drawTurnoverRateBars(Canvas canvas, Size size) {
    const titleHeight = 20.0;
    final bodyHeight = size.height - titleHeight;

    final redPaint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

    final greenPaint =
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.fill;

    double maxTurnoverRate = _calcMaxTurnoverRate();
    int nKline = 0;
    for (int i = klineRng.begin; i < klineRng.end; i++) {
      final x = nKline * klineWidth;
      final barWidth = klineInnerWidth;
      final barHeight = (klines[i].turnoverRate / maxTurnoverRate) * bodyHeight;
      final y = titleHeight + bodyHeight - barHeight;

      // 确保最小高度
      double effectiveHeight = barHeight < 2 ? 2 : barHeight;

      // 根据涨跌决定颜色
      final paint = isUpList[nKline] ? redPaint : greenPaint;

      canvas.drawRect(Rect.fromLTWH(x, y, barWidth, effectiveHeight), paint);
      nKline++;
    }
  }

  void _drawCrossLine(Canvas canvas, Size size) {
    const titleHeight = 20.0;
    final crossPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;

    final x = crossLineIndex * klineWidth + klineInnerWidth / 2;

    // 垂直线
    canvas.drawLine(Offset(x, titleHeight), Offset(x, size.height), crossPaint);
  }

  String _formatRate(double rate) {
    return '${rate.toStringAsFixed(2)}%';
  }

  // 获取可视范围K线的最大换手率
  double _calcMaxTurnoverRate() {
    if (klines.isEmpty) return 0;
    double max = 0;
    for (int i = klineRng.begin; i < klineRng.end; i++) {
      if (klines[i].turnoverRate > max) {
        max = klines[i].turnoverRate;
      }
    }
    return max;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
