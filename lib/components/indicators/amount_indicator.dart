// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/indicators/amount_indicator.dart
// Purpose:     amount indicator
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/theme/stock_colors.dart';

class AmountIndicator extends StatefulWidget {
  final KlineState klineState;
  final StockColors stockColors;
  const AmountIndicator({super.key, required this.klineState, required this.stockColors});
  @override
  State<AmountIndicator> createState() => _AmountIndicatorState();
}

class _AmountIndicatorState extends State<AmountIndicator> {
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
        painter: _AmountIndicatorPainter(
          klines: state.klines,
          klineRng: state.klineRng!,
          klineStep: state.klineStep,
          klineWidth: state.klineWidth,
          crossLineFollowKlineIndex: state.crossLineFollowKlineIndex,
          klineChartWidth: state.klineChartWidth,
          klineChartLeftMargin: state.klineChartLeftMargin,
          klineChartRightMargin: state.klineChartRightMargin,
          indicatorChartTitleBarHeight: state.indicatorChartTitleBarHeight,
          stockColors: widget.stockColors,
          isUpList: _getIsUpList(state.klines, state.klineRng!),
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
  final int crossLineFollowKlineIndex;
  final double klineStep;
  final double klineWidth;
  final List<bool> isUpList;
  final double klineChartWidth;
  final double klineChartLeftMargin;
  final double klineChartRightMargin;
  late final double maxAmount;
  final double indicatorChartTitleBarHeight;
  final StockColors stockColors;

  _AmountIndicatorPainter({
    required this.klines,
    required this.klineRng,
    required this.crossLineFollowKlineIndex,
    required this.klineStep,
    required this.klineWidth,
    required this.isUpList,
    required this.klineChartWidth,
    required this.klineChartLeftMargin,
    required this.klineChartRightMargin,
    required this.indicatorChartTitleBarHeight,
    required this.stockColors,
  }) {
    maxAmount = _calcMaxAmount();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (klines.isEmpty) return;

    // 绘制标题栏
    _drawTitleBar(canvas, size);
    // 绘制成交额柱状图
    _drawAmountBars(canvas, size.height);
    // 绘制左边成交额指示面板
    canvas.save();
    canvas.translate(-2, 0);
    drawKlinePane(
      type: KlinePaneType.amount,
      canvas: canvas,
      width: klineChartLeftMargin,
      height: size.height,
      reference: 0,
      min: 0,
      max: maxAmount,
      nRows: 4,
      textAlign: TextAlign.right,
      fontSize: 11,
      offsetY: indicatorChartTitleBarHeight,
    );
    canvas.restore();

    // 绘制右边成交额指示面板
    canvas.save();
    canvas.translate(klineChartLeftMargin + klineChartWidth + 2, 0);
    drawKlinePane(
      type: KlinePaneType.amount,
      canvas: canvas,
      width: klineChartLeftMargin,
      height: size.height,
      reference: 0,
      min: 0,
      max: maxAmount,
      nRows: 4,
      textAlign: TextAlign.left,
      fontSize: 11,
      offsetY: indicatorChartTitleBarHeight,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! _AmountIndicatorPainter) return true;
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
    if (old.klines.length != klines.length) {
      return true;
    }

    return false;
  }

  void _drawTitleBar(Canvas canvas, Size size) {
    final textStyle = TextStyle(color: Colors.white, fontSize: 12);

    // 绘制标题背景
    final bgPaint =
        Paint()
          ..color = const Color(0xFF252525)
          ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, indicatorChartTitleBarHeight), bgPaint);

    // 绘制标题文本
    final textPainter = TextPainter(
      text: TextSpan(text: '成交额', style: textStyle.copyWith(color: Colors.grey)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(4, 4));

    // 绘制昨日成交额
    final yesterdayText = TextPainter(
      text: TextSpan(
        text: '昨: ${formatAmount(klines.isNotEmpty ? klines[0].amount : 0)}',
        style: textStyle.copyWith(color: const Color.fromARGB(255, 237, 130, 8)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    yesterdayText.paint(canvas, Offset(textPainter.width + 12, 4));

    // 绘制今日成交额
    final todayText = TextPainter(
      text: TextSpan(
        text: '今: ${formatAmount(klines.isNotEmpty ? klines.last.amount : 0)}',
        style: textStyle.copyWith(color: Colors.red),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    todayText.paint(canvas, Offset(textPainter.width + yesterdayText.width + 24, 4));
  }

  void _drawAmountBars(Canvas canvas, double height) {
    final bodyHeight = height - indicatorChartTitleBarHeight;

    final redPaint =
        Paint()
          ..color = stockColors.klineUp
          ..style = PaintingStyle.fill;

    final greenPaint =
        Paint()
          ..color = stockColors.klineDown
          ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(klineChartLeftMargin, 0);
    int nKline = 0;
    for (int i = klineRng.begin; i < klineRng.end; i++) {
      final x = nKline * klineStep;
      final barWidth = klineWidth;
      final barHeight = (klines[i].amount / maxAmount) * bodyHeight;
      final y = indicatorChartTitleBarHeight + bodyHeight - barHeight;

      // 根据涨跌决定颜色
      final paint = isUpList[nKline] ? redPaint : greenPaint;

      canvas.drawRect(Rect.fromLTWH(x, y, barWidth, barHeight), paint);
      nKline++;
    }
    canvas.restore();
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
}
