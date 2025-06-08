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
  List<UiIndicator> indicators; // 当前显示的指标副图
  CrossLineMode crossLineMode; // 十字线模式
  int crossLineFollowKlineIndex; // 十字线相对K线偏移下标
  Offset crossLineFollowCursorPos; // 十字线位置
  UiKlineRange klineRng; // 可见K线范围
  double klineRngMinPrice; // 可见K线范围最低价
  double klineRngMaxPrice; // 可见K线范围最高价
  double klineStep; // K线步长
  double klineWidth; // K线宽度
  double klineChartWidth; // K线图宽度
  double klineChartHeight; // K线图高度
  double indicatorChartHeight; // k线副图高度
  double indicatorChartTitleBarHeight; // K线副图图标题栏高度
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
    required this.indicators,
    required this.crossLineMode,
    required this.crossLineFollowKlineIndex,
    required this.crossLineFollowCursorPos,
    required this.klineStep,
    required this.klineWidth,
    required this.klineChartWidth,
    required this.klineChartHeight,
    required this.indicatorChartHeight,
    required this.indicatorChartTitleBarHeight,
    required this.klineChartLeftMargin,
    required this.klineChartRightMargin,
    required this.stockColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (crossLineMode == CrossLineMode.none) return;
    if (klineType.isMinuteType) {
      drawMinuteCrossLine(canvas);
    } else {
      drawDayCrossLine(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! CrossLinePainter) return true;
    final old = oldDelegate;

    if (klines.isEmpty) {
      return false;
    }

    // 比较基础类型和引用
    if (old.crossLineMode != crossLineMode ||
        old.crossLineFollowCursorPos != crossLineFollowCursorPos ||
        old.klineStep != klineStep ||
        old.klineWidth != klineWidth ||
        old.klineType != klineType ||
        old.klineChartWidth != klineChartWidth ||
        old.klineChartHeight != klineChartHeight ||
        old.klineRng != klineRng ||
        old.stockColors != stockColors ||
        old.klineChartLeftMargin != klineChartLeftMargin ||
        old.klineChartRightMargin != klineChartRightMargin) {
      return true;
    }

    // 深度比较列表内容（假设列表顺序和长度决定是否更新）
    if (old.klines.length != klines.length ||
        old.minuteKlines.length != minuteKlines.length ||
        old.fiveDayMinuteKlines.length != fiveDayMinuteKlines.length) {
      return true;
    }
    return false;
  }

  // 分时图/5日分时图
  void drawMinuteCrossLine(Canvas canvas) {}

  // 日/周/月/季/年K线绘制
  void drawDayCrossLine(Canvas canvas) {
    if (klines.isEmpty || crossLineFollowKlineIndex > klines.length - 1) return;
    // 获取当前K线数据

    final kline = klines[crossLineFollowKlineIndex];
    final priceRange = klineRngMaxPrice - klineRngMinPrice;
    double x = 0;
    double y = 0;
    double topMargin = KlineCtrlLayout.titleBarHeight * 2 - KlineCtrlLayout.titleBarMargin;
    if (crossLineMode == CrossLineMode.followCursor) {
      x = crossLineFollowCursorPos.dx - klineChartLeftMargin;
      y = crossLineFollowCursorPos.dy - topMargin;
      ;
    } else {
      x = (crossLineFollowKlineIndex - klineRng.begin) * klineStep + klineWidth / 2;
      y = (klineRngMaxPrice - kline.priceClose) * klineChartHeight / priceRange;
    }

    if (y <= 8) {
      y = 8;
      return;
    }
    // 水平线
    drawDashedLine(
      canvas: canvas,
      startPoint: Offset(0, y),
      endPoint: Offset(klineChartWidth, y),
      color: stockColors.crossLine,
    );
    // 垂直线
    drawDashedLine(
      canvas: canvas,
      startPoint: Offset(x, 0),
      endPoint: Offset(x, klineChartHeight),
      color: stockColors.crossLine,
    );
    // 绘制副图指标里的垂直竖线
    double offsetY = klineChartHeight + indicatorChartTitleBarHeight;
    double indicatorBodyHeight = indicatorChartHeight - indicatorChartTitleBarHeight;
    for (final indicator in indicators) {
      if (indicator.visible) {
        drawDashedLine(
          canvas: canvas,
          startPoint: Offset(x, offsetY),
          endPoint: Offset(x, offsetY + indicatorBodyHeight),
          color: stockColors.crossLine,
        );
        offsetY += indicatorChartHeight;
      }
    }
  }
}
