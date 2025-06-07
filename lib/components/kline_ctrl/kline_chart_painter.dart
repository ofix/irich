// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/kline_ctrl/KlinePainter.dart
// Purpose:     kline chart painter
// Author:      songhuabiao
// Created:     2025-05-22 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/global/stock.dart';
import 'dart:math';

import 'package:irich/theme/stock_colors.dart';

class KlinePainter extends CustomPainter {
  Share share; // 当前股票
  List<UiKline> klines; // 前复权日K线数据
  KlineType klineType; // 当前绘制的K线类型
  List<MinuteKline> minuteKlines; // 分时K线数据
  List<MinuteKline> fiveDayMinuteKlines; // 五日分时K线数据
  UiKlineRange klineRng; // 可视K线范围
  List<ShareEmaCurve> emaCurves; // EMA曲线数据
  int crossLineFollowKlineIndex; // 十字线位置
  double klineStep; // K线步长
  double klineWidth; // K线宽度
  double klineChartWidth; // K线图宽度
  double klineChartHeight; // K线图高度
  double klineChartLeftMargin; // K线图左边距
  double klineChartRightMargin; // K线图右边距
  double klineRngMinPrice; // 可视K线区域最低价
  double klineRngMaxPrice; // 可视K线区域最高价

  StockColors stockColors; // 主题色

  KlinePainter({
    required this.share,
    required this.klineType,
    required this.klines,
    required this.minuteKlines,
    required this.fiveDayMinuteKlines,
    required this.klineRng,
    required this.emaCurves,
    required this.crossLineFollowKlineIndex,
    required this.klineStep,
    required this.klineWidth,
    required this.klineChartWidth,
    required this.klineChartHeight,
    required this.klineChartLeftMargin,
    required this.klineChartRightMargin,
    required this.klineRngMinPrice,
    required this.klineRngMaxPrice,
    required this.stockColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (klineType) {
      case KlineType.minute:
        {
          drawMinuteKlines(canvas);
          break;
        }
      case KlineType.fiveDay:
        {
          drawFiveDayMinuteKlines(canvas);
          break;
        }
      default:
        {
          drawDayKlines(canvas);
          break;
        }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! KlinePainter) return true;
    final old = oldDelegate;

    // 比较基础类型和引用
    if (old.klineStep != klineStep ||
        old.klineWidth != klineWidth ||
        old.share.code != share.code ||
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
        old.fiveDayMinuteKlines.length != fiveDayMinuteKlines.length ||
        old.emaCurves.length != emaCurves.length) {
      return true;
    }
    return false;
  }

  void drawDayKlines(Canvas canvas) {
    if (klines.isEmpty) {
      debugPrint("日K线数据不完整");
      return;
    }

    final priceRange = klineRngMaxPrice - klineRngMinPrice;
    final priceRatio = klineChartHeight / priceRange;

    // 红盘一字板画笔
    final redPen =
        Paint()
          ..color = stockColors.klineUp
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
    // 绿盘一字板画笔
    final greenPen =
        Paint()
          ..color = stockColors.klineDown
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
    // 收盘十字形画笔
    final greyPen =
        Paint()
          ..color = Colors.grey
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    // 红盘画笔
    final klineRedPen =
        Paint()
          ..color = stockColors.klineUp
          ..style = PaintingStyle.fill;
    // 绿盘画笔
    final klineGreenPen =
        Paint()
          ..color = stockColors.klineDown
          ..style = PaintingStyle.fill;
    // 绘制K线
    canvas.save();
    canvas.translate(klineChartLeftMargin, 0);
    int nKline = 0; // 第几根K线
    for (var i = klineRng.begin; i <= klineRng.end; i++) {
      final kline = klines[i];
      final x = nKline * klineStep;
      final centerX = x + klineWidth / 2;

      // 计算坐标
      final highY = (klineRngMaxPrice - kline.priceMax) * priceRatio;
      final lowY = (klineRngMaxPrice - kline.priceMin) * priceRatio;
      final openY = (klineRngMaxPrice - kline.priceOpen) * priceRatio;
      final closeY = (klineRngMaxPrice - kline.priceClose) * priceRatio;

      final isUp = kline.priceClose > kline.priceOpen;

      // 绘制日K线中心线
      canvas.drawLine(Offset(centerX, highY), Offset(centerX, lowY), isUp ? redPen : greenPen);

      // 非一字板情况
      if (kline.priceClose != kline.priceOpen) {
        canvas.drawRect(
          Rect.fromLTRB(x, isUp ? closeY : openY, x + klineWidth, isUp ? openY : closeY),
          isUp ? klineRedPen : klineGreenPen,
        );
      } else {
        // 一字板情况
        if (isUpLimitPrice(kline, share)) {
          canvas.drawLine(Offset(x, closeY), Offset(centerX, closeY), redPen);
        } else if (isDownLimitPrice(kline, share)) {
          canvas.drawLine(Offset(x, closeY), Offset(centerX, closeY), greenPen);
        } else {
          canvas.drawLine(Offset(x, closeY), Offset(centerX, closeY), greyPen);
        }
      }
      nKline++;
    }
    canvas.restore();

    // 绘制EMA曲线
    for (final ema in emaCurves) {
      if (ema.visible) {
        _drawEmaCurve(canvas, ema, klineRngMaxPrice, priceRatio);
      }
    }
    // 绘制左边价格指示面板
    canvas.save();
    canvas.translate(-2, 0);
    double openPrice = klines[klineRng.begin].priceOpen;
    drawKlinePane(
      type: KlinePaneType.price,
      canvas: canvas,
      width: klineChartLeftMargin,
      height: klineChartHeight,
      reference: openPrice,
      min: klineRngMinPrice,
      max: klineRngMaxPrice,
      nRows: 8,
      textAlign: TextAlign.right,
      fontSize: 11,
    );
    canvas.restore();

    // 绘制右边涨幅指示面板
    canvas.save();
    canvas.translate(klineChartLeftMargin + klineChartWidth + 2, 0);
    double minPercent = (klineRngMinPrice - openPrice) / priceRange;
    double maxPercent = (klineRngMaxPrice - openPrice) / priceRange;
    drawKlinePane(
      type: KlinePaneType.percent,
      canvas: canvas,
      width: klineChartRightMargin,
      height: klineChartHeight,
      reference: 0,
      min: minPercent,
      max: maxPercent,
      nRows: 8,
      textAlign: TextAlign.left,
      fontSize: 11,
    );
    canvas.restore();
  }

  /// 绘制EMA曲线
  /// [canvas] 画布
  /// [ema] EMA曲线数据
  /// [maxPrice] 最大价格
  /// [priceRatio] 价格比例
  void _drawEmaCurve(Canvas canvas, ShareEmaCurve ema, double maxPrice, double priceRatio) {
    // 少于2条K线数据无法绘制EMA曲线
    if (klines.length <= 2) return;
    final path = Path();
    final paint =
        Paint()
          ..color = ema.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    int nKline = 0;
    double initialX = klineWidth / 2;
    canvas.save();
    canvas.translate(klineChartLeftMargin, 0);
    for (int i = klineRng.begin; i <= klineRng.end; i++) {
      final x = nKline * klineStep + initialX;
      final y = (maxPrice - ema.emaPrice[i]) * priceRatio;

      if (i == klineRng.begin) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      nKline++;
    }
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void drawMinuteKlines(Canvas canvas) {
    if (minuteKlines.isEmpty) {
      debugPrint("分时图数据为空");
      return;
    }
    // 计算价格范围
    double minPrice = double.infinity;
    double maxPrice = -double.infinity;

    for (final kline in minuteKlines) {
      if (kline.price < minPrice) minPrice = kline.price;
      if (kline.price > maxPrice) maxPrice = kline.price;
    }
    // 计算昨日收盘价
    double yesterdayClosePrice = minuteKlines.first.price - minuteKlines.first.changeAmount;

    // 计算上下部分价格区间较大的那个
    double topPrice = (maxPrice - yesterdayClosePrice).abs();
    double bottomPrice = (minPrice - yesterdayClosePrice).abs();
    double changePrice = topPrice > bottomPrice ? topPrice : bottomPrice;
    minPrice = yesterdayClosePrice - changePrice;
    maxPrice = yesterdayClosePrice + changePrice;
    final priceRange = changePrice * 2;
    final priceRatio = klineChartHeight / priceRange;
    double minPercent = (minPrice - yesterdayClosePrice) / priceRange;
    double maxPercent = (maxPrice - yesterdayClosePrice) / priceRange;

    int nMinuteKlines = minuteKlines.length.clamp(0, 240);

    // 绘制分时线
    canvas.save();
    canvas.translate(klineChartLeftMargin, 0);
    final path = Path();
    final pen =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    path.moveTo(0, (maxPrice - minuteKlines.first.price) * priceRatio);
    double minuteStep = klineChartWidth / 240; // 分时图每分钟的宽度
    for (var i = 1; i < nMinuteKlines; i++) {
      final x = i * minuteStep;
      final y = (maxPrice - minuteKlines[i].price) * priceRatio;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, pen);

    // 绘制分时均线
    final avgPath = Path();
    final avgPaint =
        Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    avgPath.moveTo(0, (maxPrice - minuteKlines.first.avgPrice) * priceRatio);
    for (var i = 1; i < nMinuteKlines; i++) {
      final x = i * minuteStep;
      final y = (maxPrice - minuteKlines[i].avgPrice) * priceRatio;
      avgPath.lineTo(x, y);
    }
    canvas.drawPath(avgPath, avgPaint);
    canvas.restore();

    // 绘制网格
    canvas.save();
    canvas.translate(klineChartLeftMargin, 0);
    drawGrid(
      canvas: canvas,
      width: klineChartWidth,
      height: klineChartHeight,
      nRows: 8,
      nCols: 8,
      nBigRows: 7,
      nBigCols: 7,
      color: Colors.grey,
    );
    canvas.restore();

    // 绘制左边价格指示面板
    canvas.save();
    canvas.translate(-2, 0);
    drawKlinePane(
      type: KlinePaneType.minutePrice,
      canvas: canvas,
      width: klineChartLeftMargin,
      height: klineChartHeight,
      reference: yesterdayClosePrice,
      min: minPrice,
      max: maxPrice,
      nRows: 8,
      textAlign: TextAlign.right,
      fontSize: 11,
    );
    canvas.restore();

    // 绘制右边涨幅指示面板
    canvas.save();
    canvas.translate(klineChartLeftMargin + klineChartWidth + 2, 0);
    drawKlinePane(
      type: KlinePaneType.minutePercent,
      canvas: canvas,
      width: klineChartRightMargin,
      height: klineChartHeight,
      reference: 0,
      min: minPercent,
      max: maxPercent,
      nRows: 8,
      textAlign: TextAlign.left,
      fontSize: 11,
    );
    canvas.restore();
  }

  // 绘制五日分时图
  void drawFiveDayMinuteKlines(Canvas canvas) {
    if (fiveDayMinuteKlines.isEmpty) {
      debugPrint("五日线数据为空!");
      return;
    }
    double maxPrice = double.negativeInfinity;
    double minPrice = double.infinity;
    for (final minuteKline in fiveDayMinuteKlines) {
      if (minuteKline.price > maxPrice) maxPrice = minuteKline.price;
      if (minuteKline.price < minPrice) minPrice = minuteKline.price;
    }
    final refClosePrice = fiveDayMinuteKlines.first.price - fiveDayMinuteKlines.first.changeAmount;
    // 计算最大波动幅度
    double maxDelta = max((maxPrice - refClosePrice).abs(), (minPrice - refClosePrice).abs());
    if (maxDelta < 0.08) {
      maxDelta = 0.08;
    }
    double priceRange = 2 * maxDelta;
    maxPrice = refClosePrice + maxDelta;
    minPrice = refClosePrice - maxDelta;
    double minPercent = (minPrice - refClosePrice) / priceRange;
    double maxPercent = (maxPrice - refClosePrice) / priceRange;
    final hZoomRatio = -klineChartHeight / priceRange;

    // 绘制网格
    canvas.save();
    canvas.translate(klineChartLeftMargin, 0);
    drawGrid(
      canvas: canvas,
      width: klineChartWidth,
      height: klineChartHeight,
      nRows: 4,
      nCols: 16,
      nBigRows: 2,
      nBigCols: 2,
      color: Colors.grey,
    );
    canvas.restore();

    // 绘制左边价格指示面板
    canvas.save();
    canvas.translate(-2, 0);
    drawKlinePane(
      type: KlinePaneType.minutePrice,
      canvas: canvas,
      width: klineChartLeftMargin,
      height: klineChartHeight,
      reference: refClosePrice,
      min: minPrice,
      max: maxPrice,
      nRows: 8,
      textAlign: TextAlign.right,
      fontSize: 11,
    );
    canvas.restore();

    // 绘制右边涨幅指示面板
    canvas.save();
    canvas.translate(klineChartLeftMargin + klineChartWidth + 2, 0);
    drawKlinePane(
      type: KlinePaneType.minutePercent,
      canvas: canvas,
      width: klineChartRightMargin,
      height: klineChartHeight,
      reference: 0,
      min: minPercent,
      max: maxPercent,
      nRows: 8,
      textAlign: TextAlign.left,
      fontSize: 11,
    );
    canvas.restore();

    // 限制最大绘制数量
    final nTotalLine = fiveDayMinuteKlines.length > 1200 ? 1200 : fiveDayMinuteKlines.length;
    final w = klineChartWidth / 1200;
    // 准备绘制路径
    final pricePath = Path();
    final avgPricePath = Path();
    canvas.save();
    canvas.translate(klineChartLeftMargin, 0);
    // 计算所有点
    MinuteKline kline;
    double x, y, yAvg;
    pricePath.moveTo(0, (fiveDayMinuteKlines.first.price - maxPrice) * hZoomRatio);
    avgPricePath.moveTo(0, (fiveDayMinuteKlines.first.avgPrice - maxPrice) * hZoomRatio);
    for (var i = 1; i < nTotalLine; i++) {
      kline = fiveDayMinuteKlines[i];
      x = i * w;
      y = (kline.price - maxPrice) * hZoomRatio;
      yAvg = (kline.avgPrice - maxPrice) * hZoomRatio;
      pricePath.lineTo(x, y);
      avgPricePath.lineTo(x, yAvg);
    }
    // 绘制分时线
    canvas.drawPath(
      pricePath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // 绘制分时均线
    canvas.drawPath(
      avgPricePath,
      Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // 绘制渐变填充区域
    final fillPath =
        Path.from(pricePath)
          ..lineTo(nTotalLine * w, klineChartHeight)
          ..lineTo(0, klineChartHeight)
          ..close();
    final gradient = LinearGradient(
      colors: [Colors.red.withOpacity(0.24), Colors.red.withOpacity(0.02)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, klineChartWidth, klineChartHeight)),
    );
    canvas.restore();
  }
}
