// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/kline_ctrl/KlinePainter.dart
// Purpose:     kline chart painter
// Author:      songhuabiao
// Created:     2025-05-22 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/global/stock.dart';
import 'dart:math';

class KlinePainter extends CustomPainter {
  Share share; // 当前股票
  List<UiKline> klines; // 前复权日K线数据
  KlineType klineType; // 当前绘制的K线类型
  List<MinuteKline> minuteKlines; // 分时K线数据
  List<MinuteKline> fiveDayMinuteKlines; // 五日分时K线数据
  UiKlineRange klineRng; // 可视K线范围
  List<ShareEmaCurve> emaCurves; // EMA曲线数据
  int crossLineIndex; // 十字线位置
  double klineWidth; // K线宽度
  double klineInnerWidth; // K线内部宽度

  double minKlinePrice = 0.0; // 可视区域K线最低价
  double maxKlinePrice = 0.0; // 可视区域K线最高价
  double minRectPrice = 0.0; // 如果有EMA均线，可视区域最低价会变化
  double maxRectPrice = 0.0; // 如果有EMA均线，可视区域最高价会变化
  int minRectPriceIndex = 0; // 可见K线中最低价K线位置
  int maxRectPriceIndex = 0; // 可见K险种最高价K线位置

  KlinePainter({
    required this.share,
    required this.klineType,
    required this.klines,
    required this.minuteKlines,
    required this.fiveDayMinuteKlines,
    required this.klineRng,
    required this.emaCurves,
    required this.crossLineIndex,
    required this.klineWidth,
    required this.klineInnerWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!klineType.isMinuteType) {
      if (klines.isEmpty) {
        return;
      }
    }
    // 绘制背景
    _drawBackground(canvas, size);

    // 根据不同类型绘制K线
    switch (klineType) {
      case KlineType.minute:
        {
          _drawMinuteKlines(canvas, size);
          break;
        }
      case KlineType.fiveDay:
        {
          _drawFiveDayMinuteKlines(canvas, size);
          break;
        }
      default:
        _drawDayKlines(canvas, size);
    }

    // 绘制十字线
    if (crossLineIndex != -1) {
      _drawCrossLine(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  // 获取可见K线范围内的最高价
  void _calcRectMaxPrice(List<UiKline> klines, int begin, int end) {
    double max = double.negativeInfinity;
    for (int i = begin; i <= end; i++) {
      if (klines[i].priceMax > max) {
        max = klines[i].priceMax;
      }
    }
    maxKlinePrice = max;
    if (emaCurves.isNotEmpty) {
      for (final curve in emaCurves) {
        if (curve.visible) {
          for (int i = begin; i <= end; i++) {
            if (curve.emaPrice[i] > max) {
              max = curve.emaPrice[i];
            }
          }
        }
      }
    }
    maxRectPrice = max;
  }

  // 获取可见K线范围内的最低价
  void _calcRectMinPrice(List<UiKline> klines, int begin, int end) {
    double min = double.infinity;
    for (int i = begin; i <= end; i++) {
      if (klines[i].priceMax < min) {
        min = klines[i].priceMax;
      }
    }
    minKlinePrice = min;
    if (emaCurves.isNotEmpty) {
      for (final curve in emaCurves) {
        if (curve.visible) {
          for (int i = begin; i <= end; i++) {
            if (curve.emaPrice[i] < min) {
              min = curve.emaPrice[i];
            }
          }
        }
      }
    }
    minRectPrice = min;
  }

  // 绘制K线背景
  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint =
        Paint()
          ..color = const Color(0xFF1E1E1E)
          ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 绘制网格线
    final gridPaint =
        Paint()
          ..color = const Color(0xFF333333)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    // 水平网格线
    const horizontalLines = 8;
    final hStep = size.height / horizontalLines;
    for (var i = 0; i <= horizontalLines; i++) {
      final y = i * hStep;
      canvas.drawLine(Offset(0, y), Offset(0 + size.width, y), gridPaint);
    }
    _calcRectMaxPrice(klines, klineRng.begin, klineRng.end);
    // 垂直网格线
    const verticalLines = 6;
    final vStep = size.width / verticalLines;
    for (var i = 0; i <= verticalLines; i++) {
      final x = i * vStep;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  void _drawDayKlines(Canvas canvas, Size size) {
    _calcRectMaxPrice(klines, klineRng.begin, klineRng.end);
    _calcRectMinPrice(klines, klineRng.begin, klineRng.end);

    final priceRange = maxRectPrice - minRectPrice;
    final priceRatio = size.height / priceRange;

    final maxPrice = maxRectPrice;
    // 红盘一字板画笔
    final redPen =
        Paint()
          ..color = Colors.red
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
    // 绿盘一字板画笔
    final greenPen =
        Paint()
          ..color = Colors.green
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
          ..color = Colors.red
          ..style = PaintingStyle.fill;
    final klineGreenPen =
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.fill;
    // 绿盘画笔
    // 绘制K线
    int nKline = 0; // 第几根K线
    double deltaWidth = 3;
    if (size.width <= klines.length) {
      deltaWidth = size.width / klines.length;
    } else {
      deltaWidth = klineWidth;
    }
    for (var i = klineRng.begin; i <= klineRng.end; i++) {
      final kline = klines[i];
      final x = nKline * deltaWidth;
      final centerX = x + klineInnerWidth / 2;

      // 计算坐标
      final highY = (maxPrice - kline.priceMax) * priceRatio;
      final lowY = (maxPrice - kline.priceMin) * priceRatio;
      final openY = (maxPrice - kline.priceOpen) * priceRatio;
      final closeY = (maxPrice - kline.priceClose) * priceRatio;

      final isUp = kline.priceClose > kline.priceOpen;

      // 绘制日K线中心线
      canvas.drawLine(Offset(centerX, highY), Offset(centerX, lowY), isUp ? redPen : greenPen);

      // 非一字板情况
      if (kline.priceClose != kline.priceOpen) {
        canvas.drawRect(
          Rect.fromLTRB(x, isUp ? closeY : openY, x + klineInnerWidth, isUp ? openY : closeY),
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

    // 绘制EMA曲线
    for (final ema in emaCurves) {
      if (ema.visible) {
        _drawEmaCurve(canvas, ema, maxPrice, priceRatio, size);
      }
    }
  }

  /// 绘制EMA曲线
  /// [canvas] 画布
  /// [ema] EMA曲线数据
  /// [maxPrice] 最大价格
  /// [priceRatio] 价格比例
  void _drawEmaCurve(
    Canvas canvas,
    ShareEmaCurve ema,
    double maxPrice,
    double priceRatio,
    Size size,
  ) {
    // 少于2条K线数据无法绘制EMA曲线
    if (klines.length <= 2) return;
    final path = Path();
    final paint =
        Paint()
          ..color = ema.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    int nKline = 0;
    double initialX = klineInnerWidth / 2;
    double deltaWidth = 3;
    if (size.width <= klines.length) {
      deltaWidth = size.width / klines.length;
    } else {
      deltaWidth = klineWidth;
    }
    for (int i = klineRng.begin; i <= klineRng.end; i++) {
      final x = nKline * deltaWidth + initialX;
      final y = (maxPrice - ema.emaPrice[i]) * priceRatio;

      if (i == klineRng.begin) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      nKline++;
    }
    canvas.drawPath(path, paint);
  }

  void _drawMinuteKlines(Canvas canvas, Size size) {
    if (minuteKlines.isEmpty) {
      debugPrint("分时图数据为空");
      return;
    }

    // 计算价格范围
    var minPrice = double.infinity;
    var maxPrice = -double.infinity;

    for (final kline in minuteKlines) {
      if (kline.price < minPrice) minPrice = kline.price;
      if (kline.price > maxPrice) maxPrice = kline.price;
    }

    final priceRange = maxPrice - minPrice;
    final priceRatio = size.height / priceRange;

    // 绘制分时线
    final path = Path();
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    for (var i = 0; i < minuteKlines.length; i++) {
      final kline = minuteKlines[i];
      final x = i * (size.width / 240);
      final y = (maxPrice - kline.price) * priceRatio;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // 绘制均线
    final avgPath = Path();
    final avgPaint =
        Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    for (var i = 0; i < minuteKlines.length; i++) {
      final kline = minuteKlines[i];
      final x = i * (size.width / 240);
      final y = (maxPrice - kline.avgPrice) * priceRatio;

      if (i == 0) {
        avgPath.moveTo(x, y);
      } else {
        avgPath.lineTo(x, y);
      }
    }

    canvas.drawPath(avgPath, avgPaint);
  }

  void _drawFiveDayMinuteKlineBackground(
    Canvas canvas,
    Size size,
    double refClosePrice,
    double deltaPrice,
  ) {
    const nRows = 16;
    const nCols = 20;
    final wRect = size.width;
    double hRect = 2000;
    final hRow = (hRect - (nRows + 2)) / nRows;
    final wCol = wRect / nCols;
    final dwCol = wRect / 5;

    // Define pens (paints)
    final solidPen =
        Paint()
          ..color = const Color(0xFF555555) // KLINE_PANEL_BORDER_COLOR
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    final solidPen2 =
        Paint()
          ..color = const Color(0xFF555555)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final dotPen =
        Paint()
          ..color = const Color(0xFF555555)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // Calculate prices and amplitudes
    final prices = <double>[];
    final amplitudes = <double>[];
    final rowPrice = deltaPrice * 2 / nRows;

    if (rowPrice < 0.01) {
      for (var i = 0; i < 8; i++) {
        prices.add(refClosePrice + 0.01 * (i + 1));
        amplitudes.add((prices[i] / refClosePrice - 1) * 100);
      }
      for (var i = 0; i < 8; i++) {
        prices.add(refClosePrice - 0.01 * (i + 1));
        amplitudes.add((1 - prices[i] / refClosePrice) * 100);
      }
    } else {
      for (var i = 0; i < 8; i++) {
        prices.add(refClosePrice + rowPrice * (i + 1));
        amplitudes.add((prices[i] / refClosePrice - 1) * 100);
      }
      for (var i = 0; i < 8; i++) {
        prices.add(refClosePrice - rowPrice * (i + 1));
        amplitudes.add(amplitudes[i]);
      }
    }

    double offsetX = 0;

    // 绘制左右外边框
    // 上边框
    canvas.drawLine(Offset(offsetX, 0), Offset(offsetX + wRect, 0), solidPen);
    // 下边框
    canvas.drawLine(Offset(offsetX, hRect), Offset(offsetX + wRect, hRect), solidPen);
    // 左边框
    canvas.drawLine(Offset(offsetX, 0), Offset(offsetX, hRect), solidPen);
    // 右边框
    canvas.drawLine(Offset(offsetX + wRect, 0), Offset(offsetX + wRect, hRect), solidPen);

    // 中间粗水平线
    canvas.drawLine(Offset(offsetX, hRect / 2), Offset(offsetX + wRect, hRect / 2), solidPen2);

    // 5日粗竖线
    final nDay = nCols ~/ 4;
    for (var i = 1; i <= nDay; i++) {
      final x = offsetX + dwCol * i;
      canvas.drawLine(Offset(x, 0), Offset(x, hRect), solidPen2);
    }

    // 垂直分割虚线
    for (var i = 1; i < nCols; i++) {
      final x = offsetX + wCol * i;
      if (i % 4 != 0) {
        final path = Path();
        path.moveTo(x, 0);
        path.lineTo(x, hRect);
        canvas.drawPath(path, dotPen);
      }
    }

    // 水平分割虚线
    for (var i = 1; i <= nRows; i++) {
      final y = (hRow + 1) * i;
      if (i == 8 || i == 16) continue; // 跳过中间虚线

      final path = Path();
      path.moveTo(offsetX, y);
      path.lineTo(offsetX + wRect, y);
      canvas.drawPath(path, dotPen);
    }

    final textStyle = TextStyle(color: Colors.white, fontSize: 10);
    final textPainter = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.right);

    // 左右两边上半部分价格和涨幅
    for (var i = 0; i < 8; i++) {
      final priceText = prices[8 - i - 1].toStringAsFixed(2);
      final amplitudeText = '${amplitudes[8 - i - 1].toStringAsFixed(2)}%';
      final y = (hRow + 1) * i + hRow / 2;

      // 左右两边开盘价格基准(上一个交易日收盘价)
      textPainter.text = TextSpan(text: priceText, style: textStyle.copyWith(color: Colors.red));
      textPainter.layout();
      textPainter.paint(canvas, Offset(offsetX - 4, y - textPainter.height / 2));

      // 左右两边上半部分价格和涨幅
      textPainter.text = TextSpan(
        text: amplitudeText,
        style: textStyle.copyWith(color: Colors.red),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(offsetX + wRect + 4, y - textPainter.height / 2));
    }

    // 中间参考价格
    final middleY = (hRow + 1) * 8 - hRow / 2;
    textPainter.text = TextSpan(text: refClosePrice.toStringAsFixed(2), style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(offsetX - 4, middleY - textPainter.height / 2));

    textPainter.text = TextSpan(text: '0.00%', style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(offsetX + wRect + 4, middleY - textPainter.height / 2));

    // 下半部分绿色
    for (var i = 8; i < 16; i++) {
      final priceText = prices[i].toStringAsFixed(2);
      final amplitudeText = '${amplitudes[i].toStringAsFixed}%';
      final y = (hRow + 1) * i + hRow / 2;

      // 左右两边开盘价格基准(上一个交易日收盘价)
      textPainter.text = TextSpan(text: priceText, style: textStyle.copyWith(color: Colors.green));
      textPainter.layout();
      textPainter.paint(canvas, Offset(offsetX - 4, y - textPainter.height / 2));

      // 左右两边下半部分价格和涨幅
      textPainter.text = TextSpan(
        text: amplitudeText,
        style: textStyle.copyWith(color: Colors.green),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(offsetX + wRect + 4, y - textPainter.height / 2));
    }
  }

  // 绘制五日分时图
  void _drawFiveDayMinuteKlines(Canvas canvas, Size size) {
    if (fiveDayMinuteKlines.isEmpty) {
      debugPrint("五日线数据为空!");
      return;
    }

    // final nKlines = state.fiveDayMinuteKlines.length;
    double maxMinutePrice = double.negativeInfinity;
    double minMinutePrice = double.infinity;

    for (final minuteKline in fiveDayMinuteKlines) {
      if (minuteKline.price > maxMinutePrice) maxMinutePrice = minuteKline.price;
      if (minuteKline.price < minMinutePrice) minMinutePrice = minuteKline.price;
    }

    final refClosePrice = fiveDayMinuteKlines.first.price - fiveDayMinuteKlines.first.changeAmount;

    // 计算最大波动幅度
    double maxDelta = max(
      (maxMinutePrice - refClosePrice).abs(),
      (minMinutePrice - refClosePrice).abs(),
    );

    if (maxDelta < 0.08) {
      maxDelta = 0.08;
    }

    final maxPrice = refClosePrice + maxDelta;
    final hZoomRatio = -size.height / (2 * maxDelta);

    // 绘制背景
    _drawFiveDayMinuteKlineBackground(canvas, size, refClosePrice, maxPrice);

    // 限制最大绘制数量
    final nTotalLine = fiveDayMinuteKlines.length > 1200 ? 1200 : fiveDayMinuteKlines.length;
    final w = size.width / 1200;

    // 准备绘制路径
    final pricePath = Path();
    final avgPricePath = Path();
    final pricePoints = <Offset>[];
    final avgPricePoints = <Offset>[];

    // 计算所有点
    for (var i = 0; i < nTotalLine; i++) {
      final kline = fiveDayMinuteKlines[i];
      final x = i * w;
      final y = (kline.price - maxPrice) * hZoomRatio;
      final yAvg = (kline.avgPrice - maxPrice) * hZoomRatio;

      if (i == 0) {
        pricePath.moveTo(x, y);
        avgPricePath.moveTo(x, yAvg);
      } else {
        pricePath.lineTo(x, y);
        avgPricePath.lineTo(x, yAvg);
      }

      pricePoints.add(Offset(x, y));
      avgPricePoints.add(Offset(x, yAvg));
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
          ..lineTo(nTotalLine * w, size.height)
          ..lineTo(0, size.height)
          ..close();

    final gradient = LinearGradient(
      colors: [Colors.red.withOpacity(0.24), Colors.red.withOpacity(0.02)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    canvas.drawPath(
      fillPath,
      Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _drawCrossLine(Canvas canvas, Size size) {
    final crossPaint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    // 获取当前K线数据
    final kline = klines[crossLineIndex];
    final priceRange = maxRectPrice - minRectPrice;
    final y = (1 - (kline.priceClose - minRectPrice) / priceRange) * size.height;
    final x = (crossLineIndex - klineRng.begin) * klineWidth + klineInnerWidth / 2;
    // 水平线
    canvas.drawLine(Offset(0, y), Offset(size.width, y), crossPaint);
    // 垂直线
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), crossPaint);
  }
}
