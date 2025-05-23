// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/indicators/amount_indicator.dart
// Purpose:     amount indicator
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/global/stock.dart';

class AmountIndicator extends StatefulWidget {
  final double height;
  final List<UiKline> klines;
  final UiKlineRange klineRange;
  final double klineWidth;
  final double klineInnerWidth;
  final int crossLineIndex;
  const AmountIndicator({
    super.key,
    required this.klines,
    required this.klineRange,
    required this.klineWidth,
    required this.klineInnerWidth,
    required this.crossLineIndex,
    this.height = 100,
  });
  @override
  State<AmountIndicator> createState() => _AmountIndicatorState();
}

class _AmountIndicatorState extends State<AmountIndicator> {
  @override
  Widget build(BuildContext context) {
    // final klineState = ref.watch(klineProvider);

    if (widget.klines.isEmpty) {
      return SizedBox(height: widget.height);
    }

    return SizedBox(
      height: widget.height,
      child: CustomPaint(
        painter: _AmountIndicatorPainter(
          klines: widget.klines,
          klineRng: widget.klineRange,

          klineWidth: widget.klineWidth,
          klineInnerWidth: widget.klineInnerWidth,
          crossLineIndex: widget.crossLineIndex,
          isUpList: _getIsUpList(widget.klines, widget.klineRange),
        ),
      ),
    );
  }

  List<bool> _getIsUpList(List<UiKline> klines, UiKlineRange klineRng) {
    List<bool> upList = [];
    for (int i = klineRng.begin; i < klineRng.end; i++) {
      upList.add(klines[i].priceClose >= klines[i].priceOpen);
    }
    return upList;
  }
}

class _AmountIndicatorPainter extends CustomPainter {
  final List<UiKline> klines;
  final UiKlineRange klineRng;
  final int crossLineIndex;
  final double klineWidth;
  final double klineInnerWidth;
  final List<bool> isUpList;

  _AmountIndicatorPainter({
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
    // 绘制成交额柱状图
    _drawAmountBars(canvas, size);
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
      text: TextSpan(text: '成交额', style: textStyle.copyWith(color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(4, 4));

    // 绘制昨日成交额
    final yesterdayText = TextPainter(
      text: TextSpan(
        text: '昨: ${_formatAmount(klines.isNotEmpty ? klines[0].amount : 0)}',
        style: textStyle.copyWith(color: Colors.grey),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    yesterdayText.paint(canvas, Offset(textPainter.width + 12, 4));

    // 绘制今日成交额
    final todayText = TextPainter(
      text: TextSpan(
        text: '今: ${_formatAmount(klines.isNotEmpty ? klines.last.amount : 0)}',
        style: textStyle.copyWith(color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    todayText.paint(canvas, Offset(textPainter.width + yesterdayText.width + 24, 4));
  }

  void _drawAmountBars(Canvas canvas, Size size) {
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

    double maxAmount = _calcMaxAmount();
    for (int i = klineRng.begin; i < klineRng.end; i++) {
      final x = i * klineWidth;
      final barWidth = klineInnerWidth;
      final barHeight = (klines[i].amount / maxAmount) * bodyHeight;
      final y = titleHeight + bodyHeight - barHeight;

      // 根据涨跌决定颜色
      final paint = isUpList[i] ? redPaint : greenPaint;

      canvas.drawRect(Rect.fromLTWH(x, y, barWidth, barHeight), paint);
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

  String _formatAmount(double amount) {
    if (amount >= 100000000) {
      return '${(amount / 100000000).toStringAsFixed(2)}亿';
    } else if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(2)}万';
    }
    return amount.toStringAsFixed(2);
  }

  double _calcMaxAmount() {
    if (klines.isEmpty) return 0;
    double maxAmount = 0;
    for (int i = klineRng.begin; i < klineRng.end; i++) {
      if (klines[i].amount > maxAmount) {
        maxAmount = klines[i].amount;
      }
    }
    return maxAmount;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
