// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/kline_ctrl/kline_chart_state.dart
// Purpose:     kline chart core classes and common drawing helper functions
// Author:      songhuabiao
// Created:     2025-06-04 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/indicators/amount_indicator.dart';
import 'package:irich/components/indicators/boll_indicator.dart';
import 'package:irich/components/indicators/kdj_indicator.dart';
import 'package:irich/components/indicators/macd_indicator.dart';
import 'package:irich/components/indicators/minute_amount_indicator.dart';
import 'package:irich/components/indicators/minute_volume_indicator.dart';
import 'package:irich/components/indicators/turnoverrate_indicator.dart';
import 'package:irich/components/indicators/volume_indicator.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/settings/ema_curve_setting.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/theme/stock_colors.dart';

enum CrossLineMode {
  none, // 不显示
  followCursor, // 跟随光标
  followKline, // 跟随K线
}

enum KlineWndMode {
  full, // 全功能界面
  mini, // 迷你模式
}

enum MinuteKlineWndMode {
  normal('正常模式'),
  limitUp('涨停模式'),
  ema('EMA模式');

  final String displayName;
  const MinuteKlineWndMode(this.displayName);

  String get name => toString().split('.').last;
  static MinuteKlineWndMode? fromVal(String displayName) {
    switch (displayName) {
      case '正常模式':
        return MinuteKlineWndMode.normal;
      case '涨停模式':
        return MinuteKlineWndMode.limitUp;
      case 'EMA模式':
        return MinuteKlineWndMode.ema;
      default:
        return null; // 无匹配时返回null
    }
  }
}

// 分时价格区间
class MinutePriceZone {
  int period; // 周期
  double price; // 价格
  Color color; // 颜色
  MinutePriceZone(this.period, this.price, this.color);
}

class ColorText {
  String text; // 文本
  Color color; // 颜色
  ColorText(this.text, this.color);
}

// K线组件布局相关默认值
class KlineCtrlLayout {
  static const double titleBarHeight = 32;
  static const double titleBarMargin = 4;
  static const double klineChartLeftMargin = 50;
  static const double klineChartRightMargin = 50;
}

// K线组件核心类
class KlineCtrlState {
  KlineWndMode wndMode; // 窗口模式
  MinuteKlineWndMode minuteWndMode; // 分时图窗口模式
  String shareCode; // 股票代码
  Share? share; // 股票
  KlineType klineType = KlineType.day; // 当前绘制的K线类型
  List<UiKline> klines; // 前复权日K线数据
  List<MinuteKline> minuteKlines; // 分时K线数据，按需填充
  List<MinuteKline> fiveDayMinuteKlines; // 五日分时K线数据，按需填充
  List<ShareEmaCurve> emaCurves; // EMA曲线数据，按需填充
  // 副图指标数据
  Map<String, List<double>> kdj; // KDJ技术指标数据，按需填充
  Map<String, List<double>> macd; // MACD技术指标数据，按需填充
  Map<String, List<double>> boll; // 布林线技术指标数据，按需填充
  List<UiIndicator> indicators; //  当前显示的指标副图，日/周/月/季/年K线技术指标列表, 分时图技术指标列表,  五日分时图技术指标列表
  List<UiIndicator> dynamicIndicators; // 日/周/月/季/年K线技术指标列表,支持动态添加和删除
  // EMA曲线
  List<EmaCurveSetting> emaCurveSettings; // 用户可以自定义EMA曲线样式和数量
  CrossLineMode crossLineMode; // 十字线模式
  Offset crossLineFollowCursorPos; // 十字线，跟随光标位置
  int crossLineFollowKlineIndex; // 十字线，所属K线位置
  // K线布局参数
  double klineStep; // K线步长
  double klineWidth; // K线宽度
  UiKlineRange klineRng; // 可视K线范围
  double klineRngMinPrice; // 可见范围K线最低价
  double klineRngMaxPrice; // 可见范围K线最高价
  int visibleKlineCount; // 可视区域K线数量
  // K线组件布局参数
  double klineCtrlWidth; // K线图容器宽度(主图+左右指示面板)
  double klineCtrlHeight; // K线图容器高度(主图+多个附图)
  double klineCtrlTitleBarHeight; // K线图标题栏高度
  double klineChartWidth; // K线图宽度
  double klineChartHeight; // K线图高度
  double klineChartLeftMargin; // K线图左边宽度(显示价格指示图)
  double klineChartRightMargin; // K线图右边宽度(显示涨幅指示图)
  double indicatorChartHeight; // 指标附图高度
  double indicatorChartTitleBarHeight; // 指标附图标题栏高度
  int refreshCount; // 交易时间定时刷新次数
  bool dataLoaded; // 数据加载完成

  KlineCtrlState({
    required this.shareCode,
    required this.klineType, // 日/周/月/季/年 k线参数
    Share? share,
    List<UiKline>? klines,
    List<MinuteKline>? minuteKlines,
    List<MinuteKline>? fiveDayMinuteKlines,
    UiKlineRange? klineRng,
    List<ShareEmaCurve>? emaCurves, // EMA曲线数据
    List<UiIndicator>? indicators, // 副图指标数据
    List<UiIndicator>? dynamicIndicators,
    Map<String, List<double>>? kdj,
    Map<String, List<double>>? macd,
    Map<String, List<double>>? boll,
    this.wndMode = KlineWndMode.full,
    this.minuteWndMode = MinuteKlineWndMode.normal,
    this.klineRngMinPrice = double.infinity,
    this.klineRngMaxPrice = double.negativeInfinity,
    this.crossLineMode = CrossLineMode.none, // 十字线参数
    this.crossLineFollowKlineIndex = -1,
    this.crossLineFollowCursorPos = const Offset(-1, -1),
    this.klineStep = 17, // 布局参数
    this.klineWidth = 15,
    this.visibleKlineCount = 120,
    this.klineCtrlWidth = 0,
    this.klineCtrlHeight = 0,
    this.klineCtrlTitleBarHeight = 32,
    this.klineChartWidth = 0,
    this.klineChartHeight = 0,
    this.klineChartLeftMargin = KlineCtrlLayout.klineChartLeftMargin,
    this.klineChartRightMargin = KlineCtrlLayout.klineChartRightMargin,
    this.indicatorChartHeight = 80,
    this.indicatorChartTitleBarHeight = KlineCtrlLayout.titleBarHeight,
    this.refreshCount = 0,
    this.dataLoaded = false,
    List<EmaCurveSetting>? emaCurveSettings,
  }) : klines = klines ?? [], // 使用const空列表避免共享引用
       minuteKlines = minuteKlines ?? [],
       fiveDayMinuteKlines = fiveDayMinuteKlines ?? [],
       klineRng = klineRng ?? UiKlineRange(begin: 0, end: 0),
       emaCurves = emaCurves ?? [],
       kdj = kdj ?? {},
       macd = macd ?? {},
       boll = boll ?? {},
       indicators = indicators ?? [],
       dynamicIndicators = dynamicIndicators ?? [],
       share = share ?? StoreQuote.query(shareCode),
       emaCurveSettings = defaultEmaCurveSettings;

  // 深拷贝方法（可选）
  KlineCtrlState copyWith({
    String? shareCode,
    Share? share,
    KlineWndMode? wndMode,
    MinuteKlineWndMode? minuteWndMode,
    KlineType? klineType,
    List<UiKline>? klines,
    List<MinuteKline>? minuteKlines,
    List<MinuteKline>? fiveDayMinuteKlines,
    List<ShareEmaCurve>? emaCurves,
    Map<String, List<double>>? kdj,
    Map<String, List<double>>? macd,
    Map<String, List<double>>? boll,
    List<UiIndicator>? indicators,
    List<UiIndicator>? dynamicIndicators,
    UiKlineRange? klineRng,
    double? klineRngMinPrice,
    double? klineRngMaxPrice,
    int? visibleIndicatorIndex,
    CrossLineMode? crossLineMode,
    int? crossLineFollowKlineIndex,
    Offset? crossLineFollowCursorPos,
    double? klineStep,
    double? klineWidth,
    int? visibleKlineCount,
    double? klineCtrlWidth,
    double? klineCtrlHeight,
    double? klineCtrlTitleBarHeight,
    double? klineChartWidth,
    double? klineChartHeight,
    double? klineChartLeftMargin,
    double? klineChartRightMargin,
    double? indicatorChartHeight,
    double? indicatorChartTitleBarHeight,
    List<EmaCurveSetting>? emaCurveSettings,
    int? refreshCount,
    bool? dataLoaded,
  }) {
    return KlineCtrlState(
      wndMode: wndMode ?? this.wndMode,
      minuteWndMode: minuteWndMode ?? this.minuteWndMode,
      shareCode: shareCode ?? this.shareCode,
      share: share ?? this.share,
      klineType: klineType ?? this.klineType,
      klines: klines ?? this.klines,
      minuteKlines: minuteKlines ?? this.minuteKlines,
      fiveDayMinuteKlines: fiveDayMinuteKlines ?? this.fiveDayMinuteKlines,
      emaCurves: emaCurves ?? this.emaCurves,
      kdj: kdj ?? this.kdj,
      macd: macd ?? this.macd,
      boll: boll ?? this.boll,
      indicators: indicators ?? this.indicators,
      dynamicIndicators: dynamicIndicators ?? this.dynamicIndicators,
      klineRng: klineRng ?? this.klineRng,
      klineRngMinPrice: klineRngMinPrice ?? this.klineRngMinPrice,
      klineRngMaxPrice: klineRngMaxPrice ?? this.klineRngMaxPrice,
      crossLineMode: crossLineMode ?? this.crossLineMode,
      crossLineFollowKlineIndex: crossLineFollowKlineIndex ?? this.crossLineFollowKlineIndex,
      crossLineFollowCursorPos: crossLineFollowCursorPos ?? this.crossLineFollowCursorPos,
      klineStep: klineStep ?? this.klineStep,
      klineWidth: klineWidth ?? this.klineWidth,
      visibleKlineCount: visibleKlineCount ?? this.visibleKlineCount,
      klineCtrlWidth: klineCtrlWidth ?? this.klineCtrlWidth,
      klineCtrlHeight: klineCtrlHeight ?? this.klineCtrlHeight,
      klineCtrlTitleBarHeight: klineCtrlTitleBarHeight ?? this.klineCtrlTitleBarHeight,
      klineChartWidth: klineChartWidth ?? this.klineChartWidth,
      klineChartHeight: klineChartHeight ?? this.klineChartHeight,
      klineChartLeftMargin: klineChartLeftMargin ?? this.klineChartLeftMargin,
      klineChartRightMargin: klineChartRightMargin ?? this.klineChartRightMargin,
      indicatorChartHeight: indicatorChartHeight ?? this.indicatorChartHeight,
      indicatorChartTitleBarHeight:
          indicatorChartTitleBarHeight ?? this.indicatorChartTitleBarHeight,
      emaCurveSettings: emaCurveSettings ?? this.emaCurveSettings,
      refreshCount: refreshCount ?? this.refreshCount,
      dataLoaded: dataLoaded ?? this.dataLoaded,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KlineCtrlState &&
        other.wndMode == wndMode &&
        other.minuteWndMode == minuteWndMode &&
        other.shareCode == shareCode &&
        other.klineType == klineType &&
        other.emaCurveSettings == emaCurveSettings &&
        other.crossLineMode == crossLineMode &&
        other.crossLineFollowCursorPos == crossLineFollowCursorPos &&
        other.crossLineFollowKlineIndex == crossLineFollowKlineIndex &&
        other.klineRng.begin == klineRng.begin &&
        other.klineRng.end == klineRng.end &&
        other.klineCtrlWidth == klineCtrlWidth &&
        other.klineCtrlHeight == klineCtrlHeight &&
        other.klineChartWidth == klineChartWidth &&
        other.klineChartHeight == klineChartHeight;
  }

  @override
  int get hashCode {
    return Object.hash(
      wndMode,
      minuteWndMode,
      shareCode,
      klineType,
      emaCurveSettings,
      crossLineMode,
      crossLineFollowCursorPos,
      crossLineFollowKlineIndex,
      klineRng.begin, // 直接取范围值
      klineRng.end,
      klineCtrlWidth,
      klineCtrlHeight,
      klineChartWidth,
      klineChartHeight,
    );
  }
}

enum KlinePaneType {
  price, // 价格
  percent, // 百分比
  amount, // 金额
  volume, // 成交量
  minuteAmount, // 分时图成交额
  minuteVolume, // 分时图成交量
  minutePrice, // 分时价格
  minutePercent, // 分时百分比
}

// K线类型
const Map<String, KlineType> klineTypeMap = {
  '分时': KlineType.minute,
  '五日': KlineType.fiveDay,
  '日K': KlineType.day,
  '周K': KlineType.week,
  '月K': KlineType.month,
  '季K': KlineType.quarter,
  '年K': KlineType.year,
};

final indicatorBuilders =
    <UiIndicatorType, Widget Function(KlineCtrlState state, StockColors colors)>{
      UiIndicatorType.amount:
          (state, colors) => AmountIndicator(klineCtrlState: state, stockColors: colors),
      UiIndicatorType.volume:
          (state, colors) => VolumeIndicator(klineCtrlState: state, stockColors: colors),
      UiIndicatorType.turnoverRate:
          (state, colors) => TurnoverRateIndicator(klineCtrlState: state, stockColors: colors),
      UiIndicatorType.minuteAmount:
          (state, colors) => MinuteAmountIndicator(klineCtrlState: state, stockColors: colors),
      UiIndicatorType.minuteVolume:
          (state, colors) => MinuteVolumeIndicator(klineCtrlState: state, stockColors: colors),
      UiIndicatorType.fiveDayMinuteAmount:
          (state, colors) => MinuteAmountIndicator(klineCtrlState: state, stockColors: colors),
      UiIndicatorType.fiveDayMinuteVolume:
          (state, colors) => MinuteVolumeIndicator(klineCtrlState: state, stockColors: colors),
      UiIndicatorType.macd:
          (state, colors) => MacdIndicator(klineCtrlState: state, stockColors: colors),
      UiIndicatorType.kdj:
          (state, colors) => KdjIndicator(klineCtrlState: state, stockColors: colors),
      UiIndicatorType.boll:
          (state, colors) => BollIndicator(klineCtrlState: state, stockColors: colors),
    };

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
  // 垂直线
  drawDashedLine(
    canvas: canvas,
    startPoint: Offset(x, yTop),
    endPoint: Offset(x, yBottom),
    color: const Color.fromARGB(255, 58, 88, 239),
  );
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
  double offsetY = 0,
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
          offsetY: offsetY,
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
          offsetY: offsetY,
        );
        break;
      }
    case KlinePaneType.minuteAmount:
    case KlinePaneType.amount:
      {
        _drawKlinePaneStyleTwo(
          type: type,
          canvas: canvas,
          width: width,
          height: height,
          min: min,
          max: max,
          nRows: nRows,
          textAlign: textAlign,
          fontSize: fontSize,
          formatFunc: (double data) {
            return formatAmount(data);
          },
          offsetY: offsetY,
        );
        break;
      }
    case KlinePaneType.minuteVolume:
    case KlinePaneType.volume:
      {
        _drawKlinePaneStyleTwo(
          type: type,
          canvas: canvas,
          width: width,
          height: height,
          min: min,
          max: max,
          nRows: nRows,
          textAlign: textAlign,
          fontSize: fontSize,
          formatFunc: (double data) {
            return formatVolume(data);
          },
          offsetY: offsetY,
        );
        break;
      }
  }
}

String formatAmount(double amount) {
  if (amount >= 100000000) {
    return '${(amount / 100000000).toStringAsFixed(1)}亿';
  } else if (amount >= 10000) {
    return '${(amount / 10000).toStringAsFixed(1)}万';
  }
  return amount.toStringAsFixed(1);
}

String formatVolume(double volume) {
  if (volume >= 100000000) {
    return '${(volume / 100000000).toStringAsFixed(0)}亿';
  } else if (volume >= 10000) {
    return '${(volume / 10000).toStringAsFixed(0)}万';
  }
  return volume.toStringAsFixed(0);
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
  double offsetY = 0,
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

    textPainter.paint(canvas, Offset(x, y + offsetY));
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
  textPainter.paint(canvas, Offset(x, y + offsetY));
  Color bottomColor = Colors.green;
  // 绘制下半部分（最后一行不绘制，因为下面有指标副图）
  for (int i = halfSegments + 1; i < nRows; i++) {
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

    textPainter.paint(canvas, Offset(x, y + offsetY));
  }
}

void _drawKlinePaneStyleTwo({
  required KlinePaneType type,
  required Canvas canvas,
  required double width,
  required double height,
  required double min,
  required double max,
  required int nRows,
  required TextAlign textAlign,
  required double fontSize,
  required String Function(double) formatFunc,
  double offsetY = 0,
}) {
  double step = (max - min) / nRows;
  double stepHeight = height / nRows;
  double halfFontSize = fontSize / 2;
  // 最后一行不绘制，留给其他指标副图腾空间
  for (int i = 0; i < nRows; i++) {
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
      if (type == KlinePaneType.minuteAmount || type == KlinePaneType.minuteVolume) {
        y = stepHeight * i - halfFontSize;
      } else {
        y = stepHeight * i;
      }
    } else if (i == nRows) {
      y = stepHeight * i - fontSize;
    } else {
      y = stepHeight * i - halfFontSize;
    }
    textPainter.paint(canvas, Offset(x, y + offsetY));
  }
}

/// 绘制虚线
/// [canvas] 画布对象
/// [startPoint] 起始位置
/// [endPoint] 结束位置
/// [color] 绘制颜色 (默认黑色)
/// [strokeWidth] 线宽 (默认1.0)
/// [dashPattern] 虚线样式，需包含至少2个值：[实线长度, 空白长度] (默认[5.0, 3.0])
void drawDashedLine({
  required Canvas canvas,
  required Offset startPoint,
  required Offset endPoint,
  Color color = Colors.black,
  double strokeWidth = 1.0,
  List<double> dashPattern = const [2.0, 1.0],
}) {
  // 检查坐标点有效性
  if (!_isValidOffset(startPoint) || !_isValidOffset(endPoint)) {
    debugPrint('DashedLine invalid parameters: start=$startPoint, end=$endPoint');
    return;
  }
  // 参数校验
  assert(dashPattern.length >= 2, 'dashPattern must have at least 2 values');

  final paint =
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

  final path = Path();
  path.moveTo(startPoint.dx, startPoint.dy);

  final totalDistance = (endPoint - startPoint).distance;
  final dashLength = dashPattern[0];
  final gapLength = dashPattern[1];
  final segmentLength = dashLength + gapLength;

  // 避免除以零
  if (totalDistance <= 0 || segmentLength <= 0) {
    debugPrint("drawDashedLine 参数错误");
    return;
  }

  // 计算总段数（确保不为Infinity/NaN）
  final segments = (totalDistance / segmentLength).floor();
  if (segments <= 0) return; // 没有足够的空间绘制至少一段虚线

  for (int i = 0; i < segments; i++) {
    final ratioStart = (i * segmentLength) / totalDistance;
    final ratioEnd = ((i * segmentLength) + dashLength) / totalDistance;

    final currentStart = Offset.lerp(startPoint, endPoint, ratioStart)!;
    final currentEnd = Offset.lerp(startPoint, endPoint, ratioEnd)!;

    path.moveTo(currentStart.dx, currentStart.dy);
    path.lineTo(currentEnd.dx, currentEnd.dy);
  }

  canvas.drawPath(path, paint);
}

/// 检查Offset是否有效（非Infinity/NaN）
bool _isValidOffset(Offset offset) {
  return offset.dx.isFinite && offset.dy.isFinite && !offset.dx.isNaN && !offset.dy.isNaN;
}

/// 绘制K线副图指标标题栏
/// [canvas] 画布
/// [words] 标题文字
/// [offset] 文字起始偏移位置
/// [width] 标题栏宽度
/// [height] 标题栏高度
/// [bgColor] 背景颜色
/// [spacing] 文字间隔
/// [fontSize] 字体大小
void drawIndicatorTitleBar({
  required Canvas canvas,
  required List<ColorText> words,
  required Offset offset,
  required double width,
  required double height,
  Color bgColor = const Color(0xFF252525),
  double spacing = 6,
  double fontSize = 12,
}) {
  // 绘制标题栏背景
  final bgPaint =
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill;
  canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);
  // 绘制文本
  double offsetX = offset.dx;
  for (int i = 0; i < words.length; i++) {
    TextPainter painter = TextPainter(
      text: TextSpan(
        text: words[i].text,
        style: TextStyle(color: words[i].color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(offsetX, offset.dy + 8));
    offsetX += painter.width + spacing;
  }
}
