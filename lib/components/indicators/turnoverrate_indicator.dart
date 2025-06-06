// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/indicators/turnoverrate indicator.dart
// Purpose:     turnoverrate indicator
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/theme/stock_colors.dart';

class TurnoverRateIndicator extends StatefulWidget {
  final KlineState klineState;
  final StockColors stockColors;
  const TurnoverRateIndicator({super.key, required this.klineState, required this.stockColors});

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
      width: state.klineChartWidth + state.klineChartLeftMargin + state.klineChartRightMargin,
      height: state.indicatorChartHeight,
      child: CustomPaint(
        painter: _TurnoverRatePainter(
          klines: state.klines,
          klineRng: state.klineRng!,
          crossLineFollowKlineIndex: state.crossLineFollowKlineIndex,
          klineStep: state.klineStep,
          klineWidth: state.klineWidth,
          isUpList: _getIsUpList(state.klines),
          klineChartWidth: state.klineChartWidth,
          klineChartLeftMargin: state.klineChartLeftMargin,
          klineChartRightMargin: state.klineChartRightMargin,
          indicatorChartTitleBarHeight: state.indicatorChartTitleBarHeight,
          stockColors: widget.stockColors,
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
  final int crossLineFollowKlineIndex;
  final double klineStep;
  final double klineWidth;
  final List<bool> isUpList;
  final double klineChartWidth;
  final double klineChartLeftMargin;
  final double klineChartRightMargin;
  final double indicatorChartTitleBarHeight;
  final StockColors stockColors;
  late final double maxTurnoverRate;
  _TurnoverRatePainter({
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
    maxTurnoverRate = _calcMaxTurnoverRate();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制标题栏
    _drawTitleBar(canvas, size);
    // 绘制换手率柱状图
    _drawTurnoverRateBars(canvas, size.height);
    // 绘制左边换手率指示面板
    canvas.save();
    canvas.translate(-2, 0);
    drawKlinePane(
      type: KlinePaneType.percent,
      canvas: canvas,
      width: klineChartLeftMargin,
      height: size.height,
      reference: 0,
      min: 0,
      max: maxTurnoverRate / 100,
      nRows: 4,
      textAlign: TextAlign.right,
      fontSize: 11,
      offsetY: indicatorChartTitleBarHeight,
    );
    canvas.restore();

    // 绘制右边换手率指示面板
    canvas.save();
    canvas.translate(klineChartLeftMargin + klineChartWidth + 2, 0);
    drawKlinePane(
      type: KlinePaneType.percent,
      canvas: canvas,
      width: klineChartLeftMargin,
      height: size.height,
      reference: 0,
      min: 0,
      max: maxTurnoverRate / 100,
      nRows: 4,
      textAlign: TextAlign.left,
      fontSize: 11,
      offsetY: indicatorChartTitleBarHeight,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! _TurnoverRatePainter) return true;
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
    final bgPen =
        Paint()
          ..color = const Color(0xFF252525)
          ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, indicatorChartTitleBarHeight), bgPen);

    // 绘制标题文本
    final textPainter = TextPainter(
      text: TextSpan(text: '换手率', style: textStyle.copyWith(color: Colors.grey)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(4, 4));

    // 绘制昨日换手率
    String yesterdayTurnoverRate = '--';
    if (klines.isNotEmpty) {
      yesterdayTurnoverRate = _formatRate(klines.first.turnoverRate);
    }
    final yesterdayText = TextPainter(
      text: TextSpan(
        text: '昨: $yesterdayTurnoverRate',
        style: textStyle.copyWith(color: const Color.fromARGB(255, 237, 130, 8)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    yesterdayText.paint(canvas, Offset(textPainter.width + 12, 4));

    // 绘制今日换手率
    String todayTurnoverRate = '--';
    if (klines.isNotEmpty) {
      todayTurnoverRate = _formatRate(klines.last.turnoverRate);
    }
    final todayText = TextPainter(
      text: TextSpan(text: '今: $todayTurnoverRate', style: textStyle.copyWith(color: Colors.red)),
      textDirection: TextDirection.ltr,
    )..layout();
    todayText.paint(canvas, Offset(textPainter.width + yesterdayText.width + 24, 4));
  }

  void _drawTurnoverRateBars(Canvas canvas, double height) {
    if (klines.isEmpty) {
      return;
    }
    final bodyHeight = height - indicatorChartTitleBarHeight;

    final redPen =
        Paint()
          ..color = stockColors.klineUp
          ..style = PaintingStyle.fill;

    final greenPen =
        Paint()
          ..color = stockColors.klineDown
          ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(klineChartLeftMargin, 0);
    int nKline = 0;
    for (int i = klineRng.begin; i < klineRng.end; i++) {
      final x = nKline * klineStep;
      final barWidth = klineWidth;
      final barHeight = (klines[i].turnoverRate / maxTurnoverRate) * bodyHeight;
      final y = indicatorChartTitleBarHeight + bodyHeight - barHeight;

      // 确保最小高度
      double effectiveHeight = barHeight < 2 ? 2 : barHeight;
      // 根据涨跌决定颜色
      final paint = isUpList[nKline] ? redPen : greenPen;
      canvas.drawRect(Rect.fromLTWH(x, y, barWidth, effectiveHeight), paint);
      nKline++;
    }
    canvas.restore();
  }

  String _formatRate(double rate) {
    return '${rate.toStringAsFixed(0)}%';
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
}
