// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/kline_ctrl/cross_line_painter.dart
// Purpose:     cross line painter
// Author:      songhuabiao
// Created:     2025-06-06 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/global/stock.dart';

import 'package:irich/theme/stock_colors.dart';

class CrossLinePainter extends CustomPainter {
  KlineType klineType; // 当前K线类型
  List<UiKline> klines; // K线坐标
  List<MinuteKline> minuteKlines; // 分时图数据
  List<MinuteKline> fiveDayMinuteKlines; // 五日分时图数据
  int crossLineIndex; // 十字线相对K线偏移下标
  Offset crossLinePos; // 十字线位置
  UiKlineRange klineRng; // 可见K线范围
  double klineRngMinPrice; // 可见K线范围最低价
  double klineRngMaxPrice; // 可见K线范围最高价
  double klineStep; // K线步长
  double klineWidth; // K线宽度
  double klineChartWidth; // K线图宽度
  double klineChartHeight; // K线图高度
  double klineChartLeftMargin; // K线图左边距
  double klineChartRightMargin; // K线图右边距

  StockColors stockColors; // 主题色

  CrossLinePainter({
    required this.klineType,
    required this.klines,
    required this.minuteKlines,
    required this.fiveDayMinuteKlines,
    required this.klineRng,
    required this.klineRngMinPrice,
    required this.klineRngMaxPrice,
    required this.crossLineIndex,
    required this.crossLinePos,
    required this.klineStep,
    required this.klineWidth,
    required this.klineChartWidth,
    required this.klineChartHeight,
    required this.klineChartLeftMargin,
    required this.klineChartRightMargin,
    required this.stockColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (crossLineIndex == -1) return;
    if (klineType.isMinuteType) {
      drawMinuteCrossLine(canvas);
    } else {
      drawDayCrossLine(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  // 分时图/5日分时图
  void drawMinuteCrossLine(Canvas canvas) {}

  // 日/周/月/季/年K线绘制
  void drawDayCrossLine(Canvas canvas) {
    // 获取当前K线数据
    final kline = klines[crossLineIndex];
    final priceRange = klineRngMaxPrice - klineRngMinPrice;
    final y = (1 - (kline.priceClose - klineRngMinPrice) / priceRange) * klineChartHeight;
    final x = (crossLineIndex - klineRng.begin) * klineStep + klineWidth / 2;
    canvas.save();
    canvas.translate(klineChartLeftMargin, 0);
    // 水平线
    drawDashedLine(
      canvas: canvas,
      startPoint: Offset(0, y),
      endPoint: Offset(klineChartWidth, y),
      color: const Color.fromARGB(255, 32, 136, 222),
    );
    // 垂直线
    drawDashedLine(
      canvas: canvas,
      startPoint: Offset(x, 0),
      endPoint: Offset(x, klineChartHeight),
      color: const Color.fromARGB(255, 32, 136, 222),
    );

    canvas.restore();
  }
}
