// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/kline_ctrl/kline_ctrl.dart
// Purpose:     kline chart painter
// Author:      songhuabiao
// Created:     2025-05-22 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:irich/components/indicators/amount_indicator.dart';
import 'package:irich/components/indicators/minute_amount_indicator.dart';
import 'package:irich/components/indicators/minute_volume_indicator.dart';
import 'package:irich/components/indicators/turnoverrate_indicator.dart';
import 'package:irich/components/indicators/volume_indicator.dart';
import 'package:irich/components/kline_ctrl/kline_chart.dart';
import 'package:irich/components/kline_ctrl/kline_chart_common.dart';
import 'package:irich/components/text_radio_button_group.dart';
import 'package:irich/formula/formula_ema.dart';
import 'package:irich/store/store_klines.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/utils/rich_result.dart';

class KlineCtrl extends StatefulWidget {
  final Share share;
  const KlineCtrl({super.key, required this.share});
  @override
  State<KlineCtrl> createState() => _KlineCtrlState();
}

class _KlineCtrlState extends State<KlineCtrl> {
  late KlineState klineState;
  late final FocusNode _focusNode;

  // K线类型
  static const Map<String, KlineType> klineTypeMap = {
    '分时': KlineType.minute,
    '五日': KlineType.fiveDay,
    '日K': KlineType.day,
    '周K': KlineType.week,
    '月K': KlineType.month,
    '季K': KlineType.quarter,
    '年K': KlineType.year,
  };
  // EMA日K线
  static const Map<String, int> emaCurveMap = {
    'EMA5': 5,
    'EMA10': 10,
    'EMA20': 20,
    'EMA30': 30,
    'EMA60': 60,
    'EMA255': 255,
    'EMA905': 905,
  };

  // 指标附图高度动态比例(最多4个指标附图)
  static const Map<int, double> chartHeightMap = {
    0: 1, // K线主图+0个指标附图
    1: 0.8, // K线主图+1个指标附图
    2: 0.7, // K线主图+2个指标附图
    3: 0.6, // K线主图+3个指标附图
    4: 0.5, // K线主图+4个指标附图
  };

  @override
  void initState() {
    super.initState();
    klineState = KlineState(share: widget.share, klineType: KlineType.day);
    klineState.klineStep = 7;
    klineState.klineWidth = 5;
    _focusNode = FocusNode();
    _focusNode.requestFocus();
    loadKlines(); // 加载K线数据
  }

  // 加载K线数据
  Future<void> loadKlines() async {
    try {
      final store = StoreKlines();
      final result = await _queryKlines(store, klineState.share.code, klineState.klineType);
      if (!result.ok()) {
        debugPrint("数据加载失败!,${klineState.klineType.name}");
        return;
      }
      // 添加 EMA 曲线的时候会自动计算相关数据
      KlineType klineType = klineState.klineType;
      if (klineType == KlineType.day ||
          klineType == KlineType.week ||
          klineType == KlineType.month ||
          klineType == KlineType.quarter ||
          klineType == KlineType.year) {
        klineState.emaCurves.clear();
        addEmaCurve(10, Color.fromARGB(255, 255, 255, 255));
        addEmaCurve(20, Color.fromARGB(255, 239, 72, 111));
        addEmaCurve(30, Color.fromARGB(255, 255, 159, 26));
        addEmaCurve(60, Color.fromARGB(255, 201, 243, 240));
        addEmaCurve(99, Color.fromARGB(255, 255, 0, 255));
        addEmaCurve(255, Color.fromARGB(255, 255, 255, 0));
        addEmaCurve(905, Color.fromARGB(255, 0, 255, 0));
        initKlineRange(); // 初始化可见K线范围
      }

      initIndicators(); // 初始化附图指标
      setState(() {});
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      logError('Failed to load klines', error: e, stackTrace: stackTrace);
    }
  }

  // 初始化可见K线范围和数量
  void initKlineRange() {
    if (klineState.klines.length < 120) {
      klineState.visibleKlineCount = klineState.klines.length;
      klineState.klineRng!.begin = 0;
      klineState.klineRng!.end = klineState.klines.length - 1;
    } else {
      klineState.visibleKlineCount = 120; // 默认显示120根K线
      klineState.klineRng!.begin = klineState.klines.length - klineState.visibleKlineCount;
      if (klineState.klineRng!.begin < 0) {
        klineState.klineRng!.begin = 0;
      }
      klineState.klineRng!.end = klineState.klines.length - 1;
    }
  }

  // 初始化附图指标，有可能需要从文件中加载
  void initIndicators() {
    klineState.indicators = [
      [
        UiIndicator(type: UiIndicatorType.amount),
        UiIndicator(type: UiIndicatorType.volume),
        UiIndicator(type: UiIndicatorType.turnoverRate),
      ],
      [
        UiIndicator(type: UiIndicatorType.minuteAmount),
        UiIndicator(type: UiIndicatorType.minuteVolume),
      ],
      [
        UiIndicator(type: UiIndicatorType.fiveDayMinuteAmount),
        UiIndicator(type: UiIndicatorType.fiveDayMinuteVolume),
      ],
    ];
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final parentWidth = MediaQuery.of(context).size.width; 此方法获取的是屏幕宽度
    return Focus(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: Listener(
        onPointerSignal: _onMouseScroll,
        onPointerHover: _onMouseMove,
        child: GestureDetector(
          onTapDown: _onTapDown,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // final parentWidth = constraints.maxWidth; // 父容器可用宽度
              Size size = Size(constraints.maxWidth, constraints.maxHeight);
              setSize(size); // 计算K线图宽高,当前显示的K线图范围
              return Column(
                children: [
                  // K线类型切换
                  Row(children: [_buildKlineName(), _buildKlineTypeTabs()]),

                  // EMA加权平均线
                  _buildEmaCurveButtons(context, emaCurveMap),
                  // K线主图
                  KlineChart(klineState: klineState),
                  // 技术指标图
                  ..._buildIndicators(context, klineState),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildKlineName() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8), // 左右各16像素
      child: Text(
        widget.share.name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: const Color.fromARGB(255, 219, 137, 36),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildKlineTypeTabs() {
    return TextRadioButtonGroup(
      options: ["日K", "周K", "月K", "季K", "年K", "分时", "五日"],
      onChanged: (value) {
        debugPrint("onclicked ：$value");
        _onKlineTypeChanged(value);
      },
    );
  }

  // 绘制EMA曲线按钮组
  Widget _buildEmaCurveButtons(BuildContext context, Map<String, int> emaCurveMap) {
    List<Widget> widgets = [];
    for (final entry in emaCurveMap.entries) {
      Color emaColor = _getEmaColor(entry.value);
      TextButton button = TextButton(
        style: TextButton.styleFrom(foregroundColor: emaColor),
        onPressed: () => {},
        child: Text(entry.key),
      );
      widgets.add(button);
    }

    return Row(children: widgets);
  }

  // 获取EMA曲线颜色
  Color _getEmaColor(int period) {
    return switch (period) {
      5 => Colors.white,
      10 => const Color.fromARGB(255, 236, 9, 202),
      20 => const Color.fromARGB(255, 72, 105, 239),
      30 => const Color(0xFFFF9F1A),
      60 => const Color.fromARGB(255, 11, 180, 218),
      255 => const Color.fromARGB(255, 245, 16, 16),
      905 => const Color.fromARGB(255, 7, 131, 75),
      _ => Colors.purple,
    };
  }

  // 绘制技术指标附图
  List<Widget> _buildIndicators(BuildContext context, KlineState klienState) {
    final klineType = klineState.klineType;
    final indicators = klineState.indicators;
    if (indicators.isEmpty) {
      return [];
    }
    List<Widget> widgets = [];
    List<UiIndicator> currentIndicators = [];
    if (klineType == KlineType.day ||
        klineType == KlineType.week ||
        klineType == KlineType.month ||
        klineType == KlineType.quarter ||
        klineType == KlineType.year) {
      currentIndicators = indicators[0];
    } else if (klineType == KlineType.minute) {
      currentIndicators = indicators[1];
    } else if (klineType == KlineType.fiveDay) {
      currentIndicators = indicators[2];
    }

    for (int i = 0; i < currentIndicators.length; i++) {
      final type = currentIndicators[i].type;
      if (type == UiIndicatorType.amount) {
        widgets.add(AmountIndicator(klineState: klineState));
      } else if (type == UiIndicatorType.volume) {
        widgets.add(VolumeIndicator(klineState: klineState));
      } else if (type == UiIndicatorType.turnoverRate) {
        widgets.add(TurnoverRateIndicator(klineState: klineState));
      } else if (type == UiIndicatorType.minuteAmount ||
          type == UiIndicatorType.fiveDayMinuteAmount) {
        widgets.add(MinuteAmountIndicator(klineState: klineState));
      } else if (type == UiIndicatorType.minuteVolume ||
          type == UiIndicatorType.fiveDayMinuteVolume) {
        widgets.add(MinuteVolumeIndicator(klineState: klineState));
      }
    }
    return widgets;
  }

  void setSize(Size size) {
    double ratio = 1;
    if (klineState.indicators.length <= 4) {
      ratio = chartHeightMap[klineState.indicators.length]!;
    }
    double height = size.height - 103;

    klineState.klineChartWidth =
        size.width - klineState.klineChartLeftMargin - klineState.klineChartRightMargin;
    klineState.klineChartHeight = height * ratio;
    klineState.indicatorChartHeight =
        klineState.indicators.isEmpty ? 0 : height * (1 - ratio) / klineState.indicators.length;

    calcVisibleKlineWidth();
  }

  Future<RichResult> _queryKlines(StoreKlines store, String stockCode, KlineType type) async {
    final klines = _getKlinesListForType(type);
    return switch (type) {
      KlineType.day => store.queryDayKlines(stockCode, klines as List<UiKline>),
      KlineType.minute => store.queryMinuteKlines(stockCode, klines as List<MinuteKline>),
      KlineType.week => store.queryWeekKlines(stockCode, klines as List<UiKline>),
      KlineType.month => store.queryMonthKlines(stockCode, klines as List<UiKline>),
      KlineType.year => store.queryYearKlines(stockCode, klines as List<UiKline>),
      KlineType.fiveDay => store.queryFiveDayMinuteKlines(stockCode, klines as List<MinuteKline>),
      _ => error(RichStatus.shareNotExist, desc: 'Unsupported KlineType: $type'),
    };
  }

  List<dynamic> _getKlinesListForType(KlineType klineType) {
    if (klineType.isMinuteType) {
      if (klineType == KlineType.minute) {
        return klineState.minuteKlines;
      } else {
        return klineState.fiveDayMinuteKlines;
      }
    } else {
      return klineState.klines;
    }
  }

  void _onKlineTypeChanged(String value) async {
    klineState.klineType = klineTypeMap[value]!;
    await loadKlines();
    setState(() {});
  }

  void onKeyDownArrowLeft() {
    int crossLineIndex = klineState.crossLineIndex;
    UiKlineRange klineRng = klineState.klineRng!;
    if (crossLineIndex == -1) {
      // 如果十字线未设置，默认设置为最后一根K线
      crossLineIndex = klineState.klines.length - 1;
    } else if ((crossLineIndex == klineRng.begin) && (klineRng.begin > 0)) {
      klineRng.begin -= 1;
      klineRng.end -= 1;
      crossLineIndex -= 1;
    } else {
      crossLineIndex -= 1; // 向左移动十字线
    }
    klineState = klineState.copyWith(klineRng: klineRng, crossLineIndex: crossLineIndex);
    setState(() {});
  }

  void onKeyDownArrowRight() {
    final crossLineIndex = klineState.crossLineIndex;
    final klineRng = klineState.klineRng!;
    if (crossLineIndex == -1) {
      // 如果十字线未设置，默认设置为最后一根K线
      klineState.crossLineIndex = klineState.klines.length - 1;
    } else if ((crossLineIndex >= klineState.klineRng!.end) &&
        (klineRng.end < klineState.klines.length - 1)) {
      // 如果十字线在可视范围的最后一根K线上，向右移动时需要扩展可视范围
      klineState.klineRng!.begin += 1;
      klineState.klineRng!.end += 1;
      klineState.crossLineIndex += 1;
    } else if (crossLineIndex >= klineState.klines.length - 1) {
      return; // 已经是最后一根K线了,界面不需要刷新
    } else {
      klineState.crossLineIndex += 1; // 向右移动十字线
    }
    setState(() {});
  }

  // 支持鼠标上/下/左/右方向键进行缩放
  KeyEventResult _onKeyEvent(FocusNode focosNode, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        onKeyDownArrowLeft();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        onKeyDownArrowRight();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        zoomIn(); // 放大
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        zoomOut(); // 缩小
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        klineState.crossLineIndex = -1; // 清除十字线
      } else if (event.logicalKey == LogicalKeyboardKey.home) {
        klineState.crossLineIndex = klineState.klineRng!.begin;
      } else if (event.logicalKey == LogicalKeyboardKey.end) {
        klineState.crossLineIndex = klineState.klineRng!.end;
      }
      setState(() {});
      return KeyEventResult.handled;
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.home ||
          event.logicalKey == LogicalKeyboardKey.end) {
        return KeyEventResult.handled;
      }
    } else if (event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        onKeyDownArrowLeft();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        onKeyDownArrowRight();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.home ||
          event.logicalKey == LogicalKeyboardKey.end) {
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored; // ，将失去焦点
  }

  // 用户单击鼠标的时候也需要记住单击位置所在的K线下标，以此为中心点进行缩放
  void _onTapDown(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    // 计算点击的K线索引
    if ((localPosition.dx > klineState.klineChartLeftMargin) &&
        localPosition.dx < (klineState.klineChartLeftMargin + klineState.klineChartWidth)) {
      final index = (localPosition.dx / klineState.klineStep).floor();
      klineState.crossLineIndex = index + klineState.klineRng!.begin;
      setState(() {});
    }
  }

  // 鼠标移动的时候需要动态绘制十字光标
  void _onMouseMove(PointerHoverEvent event) {}

  void _onMouseScroll(PointerEvent event) {
    if (event is PointerScrollEvent) {
      setState(() {});
    }
  }

  void logError(String s, {required Object error, required StackTrace stackTrace}) {}

  void onMouseMove(PointerHoverEvent event) {}

  // 鼠标滚轮事件处理,可以用来切换股票
  void onMouseScroll(PointerEvent event) {
    if (event is PointerScrollEvent) {
      if (event.scrollDelta.dy > 0) {
      } else {}
    }
  }

  // 添加技术指标
  void addIndicator(UiIndicator indicator, int i) {
    klineState.indicators[i].add(indicator);
  }

  // 添加EMA曲线
  bool addEmaCurve(int period, Color color) {
    if (klineState.emaCurves.length >= 8) {
      // 一个界面最多显示8条EMA平滑移动价格曲线
      return false;
    }

    ShareEmaCurve curve = ShareEmaCurve(color: color, period: period, visible: true, emaPrice: []);
    curve.emaPrice = FormulaEma.calculateEma(klineState.klines, period);
    klineState.emaCurves.add(curve);
    // 刷新
    return true;
  }

  // 移除所有匹配指定周期的曲线
  bool removeEmaCurve(int period) {
    final originalLength = klineState.emaCurves.length;
    klineState.emaCurves.removeWhere((curve) => curve.period == period);
    return klineState.emaCurves.length != originalLength;
  }

  // 处理放大逻辑,可见的K线数量变少
  void zoomIn() {
    int crossLineIndex = klineState.crossLineIndex;
    UiKlineRange klineRng = klineState.klineRng!;
    if (crossLineIndex == -1) {
      crossLineIndex = klineState.klines.length - 1; // 放大中心为最右边K线
    }
    // 可见K线数量少于8，不再放大
    if (klineRng.end <= klineRng.begin + 8) {
      return;
    }

    // 计算放大中心两边的K线数量
    int leftKlineCount = crossLineIndex - klineRng.begin;
    int rightKlineCount = klineRng.end - crossLineIndex;
    // 取中心点左右两侧K线较多的一边进行延展，保住缩放中心的位置
    int count = leftKlineCount > rightKlineCount ? leftKlineCount : rightKlineCount;
    klineRng.begin = crossLineIndex - count ~/ 2;
    klineRng.end = crossLineIndex + count ~/ 2;

    // 左右边界处理
    if (klineRng.begin > klineRng.end) {
      klineRng.begin = klineRng.end - 8;
    }

    if (klineRng.begin < 0) {
      klineRng.begin = 0;
    }
    if (klineRng.end > klineState.klines.length - 1) {
      klineRng.end = klineState.klines.length - 1;
    }
    klineState = klineState.copyWith(
      klineRng: klineRng,
      visibleKlineCount: klineRng.end - klineRng.begin + 1,
      crossLineIndex: crossLineIndex,
    );
    calcVisibleKlineWidth();
  }

  // 处理K线实心宽度边界情况
  int _ensureKlineWidth(double klineStep, int klineWidth) {
    if (klineStep > 1 && klineWidth % 2 == 0) {
      klineWidth = klineWidth;
      klineWidth -= 1;
    }
    if (klineWidth < 1) {
      klineWidth = 1;
    }
    return klineWidth;
  }

  // 实现缩放逻辑，显示的K线数量变多
  void zoomOut() {
    int crossLineIndex = klineState.crossLineIndex;
    UiKlineRange klineRng = klineState.klineRng!;
    if (crossLineIndex == -1) {
      crossLineIndex = klineState.klines.length - 1; // 缩小中心为最右边K线
    }
    // 可见K线数量大于等于总K线数量，不再缩小
    if (klineState.visibleKlineCount == klineState.klines.length) {
      double klineStep = klineState.klineChartWidth / klineState.visibleKlineCount * 0.85;
      int klineWidth = (klineState.klineStep * 0.8).floor();
      klineWidth = _ensureKlineWidth(klineStep, klineWidth);
      klineState = klineState.copyWith(klineStep: klineStep, klineWidth: klineWidth.toDouble());
      return;
    }

    // 计算缩小中心两边的K线数量
    int leftKlineCount = crossLineIndex - klineRng.begin;
    int rightKlineCount = klineRng.end - crossLineIndex;
    // 取中心点左右两侧K线较多的一边进行收缩，保住缩放中心的地位
    int count = leftKlineCount > rightKlineCount ? leftKlineCount : rightKlineCount;
    klineRng.begin = crossLineIndex - count * 2;
    klineRng.end = crossLineIndex + count * 2;

    // 左右边界处理
    if (klineRng.begin < 0) {
      klineRng.begin = 0;
    }
    if (klineRng.end > klineState.klines.length - 1) {
      klineRng.end = klineState.klines.length - 1;
    }
    if (klineRng.end > klineState.klines.length - 1) {
      klineRng.end = klineState.klines.length - 1;
    }
    klineState = klineState.copyWith(
      klineRng: klineRng,
      visibleKlineCount: klineRng.end - klineRng.begin + 1,
      crossLineIndex: crossLineIndex,
    );
    calcVisibleKlineWidth();
  }

  // 计算可视范围K线自适应宽度
  void calcVisibleKlineWidth() {
    Size size = Size(klineState.klineChartWidth, klineState.klineChartHeight);
    if (klineState.klines.isEmpty) {
      return;
    }
    double klineStep;
    int klineWidth;
    klineStep = size.width / klineState.visibleKlineCount;
    klineWidth = (klineStep * 0.8).floor();
    klineWidth = _ensureKlineWidth(klineStep, klineWidth);
    klineState.klineStep = klineStep;
    klineState.klineWidth = klineWidth.toDouble();
  }
}
