// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/kline_ctrl/kline_chart_common.dart
// Purpose:     kline chart common drawing helper functions
// Author:      songhuabiao
// Created:     2025-06-04 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/global/stock.dart';

class KlineState {
  Share share; // 股票
  KlineType klineType = KlineType.day; // 当前绘制的K线类型
  List<UiKline> klines; // 前复权日K线数据
  List<MinuteKline> minuteKlines; // 分时K线数据
  List<MinuteKline> fiveDayMinuteKlines; // 五日分时K线数据
  UiKlineRange? klineRng; // 可视K线范围
  List<ShareEmaCurve> emaCurves; // EMA曲线数据
  List<List<UiIndicator>> indicators; // 0:日/周/月/季/年K线技术指标列表,1:分时图技术指标列表,2:五日分时图技术指标列表
  int crossLineIndex; // 十字线位置
  double klineStep; // K线步长
  double klineWidth; // K线宽度
  int visibleKlineCount; // 可视区域K线数量
  double klineChartWidth; // K线图宽度
  double klineChartHeight; // K线图高度
  double klineChartLeftMargin; // K线图左边宽度(显示价格指示图)
  double klineChartRightMargin; // K线图右边宽度(显示涨幅指示图)
  double indicatorChartHeight; // 指标附图高度

  KlineState({
    required this.share,
    required this.klineType,
    List<UiKline>? klines,
    List<MinuteKline>? minuteKlines,
    List<MinuteKline>? fiveDayMinuteKlines,
    List<ShareEmaCurve>? emaCurves,
    List<List<UiIndicator>>? indicators,
    UiKlineRange? klineRng,
    this.crossLineIndex = -1,
    this.klineStep = 17,
    this.klineWidth = 15,
    this.visibleKlineCount = 120,
    this.klineChartWidth = 800,
    this.klineChartHeight = 600,
    this.klineChartLeftMargin = 50,
    this.klineChartRightMargin = 50,
    this.indicatorChartHeight = 80,
  }) : klines = klines ?? [], // 使用const空列表避免共享引用
       minuteKlines = minuteKlines ?? [],
       fiveDayMinuteKlines = fiveDayMinuteKlines ?? [],
       klineRng = klineRng ?? UiKlineRange(begin: 0, end: 0),
       emaCurves = emaCurves ?? [],
       indicators = indicators ?? [];

  // 深拷贝方法（可选）
  KlineState copyWith({
    Share? share,
    KlineType? klineType,
    List<UiKline>? klines,
    List<MinuteKline>? minuteKlines,
    List<MinuteKline>? fiveDayMinuteKlines,
    UiKlineRange? klineRng,
    List<ShareEmaCurve>? emaCurves,
    List<List<UiIndicator>>? indicators,
    int? visibleIndicatorIndex,
    int? crossLineIndex,
    double? klineStep,
    double? klineWidth,
    int? visibleKlineCount,
    double? klineChartWidth,
    double? klineChartHeight,
    double? klineChartLeftMargin,
    double? klineChartRightMargin,
    double? indicatorChartHeight,
  }) {
    return KlineState(
      share: share ?? this.share,
      klineType: klineType ?? this.klineType,
      klines: klines ?? this.klines,
      minuteKlines: minuteKlines ?? this.minuteKlines,
      fiveDayMinuteKlines: fiveDayMinuteKlines ?? this.fiveDayMinuteKlines,
      klineRng: klineRng ?? this.klineRng,
      emaCurves: emaCurves ?? this.emaCurves,
      indicators: indicators ?? this.indicators,
      crossLineIndex: crossLineIndex ?? this.crossLineIndex,
      klineStep: klineStep ?? this.klineStep,
      klineWidth: klineWidth ?? this.klineWidth,
      visibleKlineCount: visibleKlineCount ?? this.visibleKlineCount,
      klineChartWidth: klineChartWidth ?? this.klineChartWidth,
      klineChartHeight: klineChartHeight ?? this.klineChartHeight,
      klineChartLeftMargin: klineChartLeftMargin ?? this.klineChartLeftMargin,
      klineChartRightMargin: klineChartRightMargin ?? this.klineChartRightMargin,
      indicatorChartHeight: indicatorChartHeight ?? this.indicatorChartHeight,
    );
  }
}

enum KlinePaneType {
  price, // 价格
  percent, // 百分比
  amount, // 金额
  minutePrice, // 分时价格
  minutePercent, // 分时百分比
}

/// 绘制边框
/// [canvas] 绘制画布
/// [width] 宽度
/// [height] 高度
/// [nRows] 横向分成几行
/// [nCols] 纵向分成几列
/// [nBigRows] 每隔几行画一根粗线
/// [nBigCols] 每隔几列画一根粗线
/// [color] 边框颜色
void drawGrid({
  required Canvas canvas,
  required double width,
  required double height,
  required int nRows,
  required int nCols,
  required int nBigRows,
  required int nBigCols,
  required Color color,
}) {
  // 绘制外边框
  final borderPen =
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

  canvas.drawRect(Rect.fromLTWH(0, 0, width, height), borderPen);

  // 绘制水平网格线
  final dotPaint =
      Paint()
        ..color = color.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
  final rowStep = height / nRows;
  for (int i = 1; i <= nRows; i++) {
    final y = i * rowStep;
    canvas.drawLine(Offset(0, y), Offset(width, y), dotPaint);
  }

  // 绘制垂直网格线
  final colStep = width / nCols;
  for (int i = 1; i < nCols; i++) {
    // if (i % nCols == 0) continue;
    final x = i * colStep;
    canvas.drawLine(Offset(x, 0), Offset(x, height), dotPaint);
  }

  final solidPaint =
      Paint()
        ..color = Colors.grey.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
  // 绘制粗横向网格线
  if (nBigRows > 0) {
    for (int i = nBigRows; i < nRows; i += nBigRows) {
      final y = i * rowStep;
      canvas.drawLine(Offset(0, y), Offset(width, y), solidPaint);
    }
  }
  // 绘制粗垂直网格线
  if (nBigCols > 0) {
    for (int i = nBigCols; i < nCols; i += nBigCols) {
      final x = i * colStep;
      canvas.drawLine(Offset(x, 0), Offset(x, height), solidPaint);
    }
  }
}

/// 绘制垂直竖线
/// [canvas] 绘制画布
/// [x] X坐标
/// [yTop] 顶部Y坐标
/// [yBottom] 底部Y坐标
void drawVerticalLine({
  required Canvas canvas,
  required double x,
  required double yTop,
  required double yBottom,
}) {
  final verticalPen =
      Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;
  // 垂直线
  canvas.drawLine(Offset(x, yTop), Offset(x, yBottom), verticalPen);
}

/// 绘制K线指示面板
/// [canvas] 绘制画布
/// [width] 绘制大小
/// [height] 绘制高度
/// [reference] 基准值
/// [min] 需要绘制的最小值
/// [max] 需要绘制的最大值
/// [nRows] 需要分割的行数
/// [textAlign] 文本对齐方式
/// [fontSize] 文字大小
/// [type] 指示面板类型
void drawKlinePane({
  required KlinePaneType type,
  required Canvas canvas,
  required double width,
  required double height,
  required double reference,
  required double min,
  required double max,
  required int nRows,
  required TextAlign textAlign,
  required double fontSize,
}) {
  switch (type) {
    case KlinePaneType.minutePrice:
    case KlinePaneType.price:
      {
        _drawKlinePaneStyleOne(
          type: type,
          canvas: canvas,
          width: width,
          height: height,
          reference: reference,
          min: min,
          max: max,
          nRows: nRows,
          textAlign: textAlign,
          fontSize: fontSize,
          formatFunc: (double data) {
            return data.toStringAsFixed(2);
          },
        );
        break;
      }
    case KlinePaneType.minutePercent:
    case KlinePaneType.percent:
      {
        _drawKlinePaneStyleOne(
          type: type,
          canvas: canvas,
          width: width,
          height: height,
          reference: reference,
          min: min,
          max: max,
          nRows: nRows,
          textAlign: textAlign,
          fontSize: fontSize,
          formatFunc: (double data) {
            return "${(data * 100).toStringAsFixed(2)}%";
          },
        );
        break;
      }
    case KlinePaneType.amount:
      {
        _drawKlinePaneStyleTwo(
          canvas: canvas,
          width: width,
          height: height,
          min: min,
          max: max,
          nRows: nRows,
          textAlign: textAlign,
          fontSize: fontSize,
          formatFunc: (double data) {
            return "${(data * 100).toStringAsFixed(2)}%";
          },
        );
        break;
      }
  }
}

void _drawKlinePaneStyleOne({
  required KlinePaneType type,
  required Canvas canvas,
  required double width,
  required double height,
  required double reference,
  required double min,
  required double max,
  required int nRows,
  required TextAlign textAlign,
  required double fontSize,
  required String Function(double) formatFunc,
}) {
  double step = (max - min) / nRows;
  double stepHeight = (height) / nRows;
  int halfSegments = (nRows / 2).floor();
  double halfFontSize = fontSize / 2;
  Color topColor = Colors.red;
  // 绘制上半部分
  for (int i = 0; i < halfSegments; i++) {
    double topValue = max - i * step;
    String label = formatFunc(topValue);
    if (type == KlinePaneType.percent || type == KlinePaneType.price) {
      topColor =
          topValue > reference
              ? Colors.red
              : topValue == reference
              ? Colors.grey
              : Colors.green;
    }
    TextPainter textPainter = TextPainter(
      text: TextSpan(text: label, style: TextStyle(color: topColor, fontSize: fontSize)),
      textDirection: TextDirection.ltr, // 文字方向（左到右）
    );
    textPainter.layout();
    double x = 0;
    if (textAlign == TextAlign.right) {
      x = width - textPainter.width; // 画布宽度 - 文本宽度
    }
    final y = (i == 0) ? 0.0 : stepHeight * i - fontSize;

    textPainter.paint(canvas, Offset(x, y));
  }
  // 绘制中间部分
  Color middleColor = Colors.grey;
  double middleValue = max - halfSegments * step;
  if (type == KlinePaneType.percent || type == KlinePaneType.price) {
    middleColor =
        middleValue > reference
            ? Colors.red
            : middleValue == reference
            ? Colors.grey
            : Colors.green;
  }
  String label = formatFunc(middleValue);
  final textPainter = TextPainter(
    text: TextSpan(text: label, style: TextStyle(color: middleColor, fontSize: fontSize)),
    textDirection: TextDirection.ltr, // 文字方向（左到右）
  );

  textPainter.layout();

  double x = 0;
  if (textAlign == TextAlign.right) {
    x = width - textPainter.width; // 画布宽度 - 文本宽度
  }
  final y = stepHeight * halfSegments - fontSize;
  textPainter.paint(canvas, Offset(x, y));
  Color bottomColor = Colors.green;
  // 绘制下半部分
  for (int i = halfSegments + 1; i <= nRows; i++) {
    double bottomValue = max - i * step;
    String label = formatFunc(bottomValue);
    if (type == KlinePaneType.percent || type == KlinePaneType.price) {
      bottomColor =
          bottomValue > reference
              ? Colors.red
              : bottomValue == reference
              ? Colors.grey
              : Colors.green;
    }
    TextPainter textPainter = TextPainter(
      text: TextSpan(text: label, style: TextStyle(color: bottomColor, fontSize: fontSize)),
      textDirection: TextDirection.ltr, // 文字方向（左到右）
    );
    textPainter.layout();
    double x = 0;
    if (textAlign == TextAlign.right) {
      x = width - textPainter.width; // 画布宽度 - 文本宽度
    }
    final y = (i == nRows) ? stepHeight * i - fontSize : stepHeight * i - halfFontSize;

    textPainter.paint(canvas, Offset(x, y));
  }
}

void _drawKlinePaneStyleTwo({
  required Canvas canvas,
  required double width,
  required double height,
  required double min,
  required double max,
  required int nRows,
  required TextAlign textAlign,
  required double fontSize,
  required String Function(double) formatFunc,
}) {
  double step = (max - min) / nRows;
  double stepHeight = (height) / nRows;
  double halfFontSize = fontSize / 2;
  // 绘制上半部分
  for (int i = 0; i <= nRows; i++) {
    String label = formatFunc(max - i * step);
    TextPainter textPainter = TextPainter(
      text: TextSpan(text: label, style: TextStyle(color: Colors.grey, fontSize: fontSize)),
      textDirection: TextDirection.ltr, // 文字方向（左到右）
    );
    textPainter.layout();
    double x = 0;
    if (textAlign == TextAlign.right) {
      x = width - textPainter.width; // 画布宽度 - 文本宽度
    }
    double y = 0;
    if (i == 0) {
      y = stepHeight * i;
    } else if (i == nRows) {
      y = stepHeight * i - fontSize;
    } else {
      y = stepHeight * i - halfFontSize;
    }
    textPainter.paint(canvas, Offset(x, y));
  }
}
