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
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:irich/components/indicators/amount_indicator.dart';
import 'package:irich/components/indicators/minute_amount_indicator.dart';
import 'package:irich/components/indicators/minute_volume_indicator.dart';
import 'package:irich/components/indicators/turnoverrate_indicator.dart';
import 'package:irich/components/indicators/volume_indicator.dart';
import 'package:irich/components/kline_ctrl/kline_chart.dart';
import 'package:irich/components/text_radio_button_group.dart';
import 'package:irich/formula/formula_ema.dart';
import 'package:irich/store/store_klines.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/utils/rich_result.dart';

class KlineState {
  String shareCode; // 股票代码
  KlineType klineType = KlineType.day; // 当前绘制的K线类型
  List<UiKline> klines; // 前复权日K线数据
  List<MinuteKline> minuteKlines; // 分时K线数据
  UiKlineRange? klineRng; // 可视K线范围
  List<ShareEmaCurve> emaCurves; // EMA曲线数据
  List<List<UiIndicator>> indicators; // 0:日/周/月/季/年K线技术指标列表,1:分时图技术指标列表,2:五日分时图技术指标列表
  int crossLineIndex; // 十字线位置
  double klineWidth; // K线宽度
  double klineInnerWidth; // K线内部宽度
  int visibleKlineCount; // 可视区域K线数量
  double width; // K线图宽度
  double klineChartHeight; // K线图高度
  double indicatorChartHeight; // 指标附图高度

  KlineState({
    required this.shareCode,
    required this.klineType,
    List<UiKline>? klines,
    List<MinuteKline>? minuteKlines,
    List<ShareEmaCurve>? emaCurves,
    List<List<UiIndicator>>? indicators,
    UiKlineRange? klineRng,
    this.crossLineIndex = -1,
    this.klineWidth = 17,
    this.klineInnerWidth = 15,
    this.visibleKlineCount = 120,
    this.width = 800,
    this.klineChartHeight = 600,
    this.indicatorChartHeight = 80,
  }) : klines = klines ?? [], // 使用const空列表避免共享引用
       minuteKlines = minuteKlines ?? [],
       klineRng = klineRng ?? UiKlineRange(begin: 0, end: 0),
       emaCurves = emaCurves ?? [],
       indicators = indicators ?? [];

  // 深拷贝方法（可选）
  KlineState copyWith({
    String? shareCode,
    KlineType? klineType,
    List<UiKline>? klines,
    List<MinuteKline>? minuteKlines,
    List<MinuteKline>? fiveDayMinuteKlines,
    UiKlineRange? klineRng,
    List<ShareEmaCurve>? emaCurves,
    List<List<UiIndicator>>? indicators,
    int? visibleIndicatorIndex,
    int? crossLineIndex,
    double? klineWidth,
    double? klineInnerWidth,
    int? visibleKlineCount,
    double? width,
    double? klineChartHeight,
    double? indicatorChartHeight,
  }) {
    return KlineState(
      shareCode: shareCode ?? this.shareCode,
      klineType: klineType ?? this.klineType,
      klines: klines ?? this.klines,
      minuteKlines: minuteKlines ?? this.minuteKlines,
      klineRng: klineRng ?? this.klineRng,
      emaCurves: emaCurves ?? this.emaCurves,
      indicators: indicators ?? this.indicators,
      crossLineIndex: crossLineIndex ?? this.crossLineIndex,
      klineWidth: klineWidth ?? this.klineWidth,
      klineInnerWidth: klineInnerWidth ?? this.klineInnerWidth,
      visibleKlineCount: visibleKlineCount ?? this.visibleKlineCount,
      width: width ?? this.width,
      klineChartHeight: klineChartHeight ?? this.klineChartHeight,
      indicatorChartHeight: indicatorChartHeight ?? this.indicatorChartHeight,
    );
  }
}

class KlineCtrl extends StatefulWidget {
  final String shareCode;
  const KlineCtrl({super.key, required this.shareCode});
  @override
  State<KlineCtrl> createState() => _KlineCtrlState();
}

class _KlineCtrlState extends State<KlineCtrl> {
  late KlineState klineState;
  late final FocusNode _focusNode;
  Timer? _holdTimer;

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
    klineState = KlineState(shareCode: widget.shareCode, klineType: KlineType.day);
    klineState.klineWidth = 7;
    klineState.klineInnerWidth = 5;
    _focusNode = FocusNode();
    _focusNode.requestFocus();
    loadKlines(); // 加载K线数据
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

  // 加载K线数据
  Future<void> loadKlines() async {
    try {
      final store = StoreKlines();
      final result = await _queryKlines(store, klineState.shareCode, klineState.klineType);
      if (!result.ok()) {
        return;
      }

      klineState.emaCurves.clear();
      // 添加 EMA 曲线的时候会自动计算相关数据
      KlineType klineType = klineState.klineType;
      if (klineType == KlineType.day ||
          klineType == KlineType.week ||
          klineType == KlineType.month ||
          klineType == KlineType.quarter ||
          klineType == KlineType.year) {
        addEmaCurve(10, Color.fromARGB(255, 255, 255, 255));
        addEmaCurve(20, Color.fromARGB(255, 239, 72, 111));
        addEmaCurve(30, Color.fromARGB(255, 255, 159, 26));
        addEmaCurve(60, Color.fromARGB(255, 201, 243, 240));
        addEmaCurve(99, Color.fromARGB(255, 255, 0, 255));
        addEmaCurve(255, Color.fromARGB(255, 255, 255, 0));
        addEmaCurve(905, Color.fromARGB(255, 0, 255, 0));
      }
      initIndicators(); // 初始化附图指标
      setState(() {});
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      logError('Failed to load klines', error: e, stackTrace: stackTrace);
    }
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
                  _buildKlineTypeTabs(),
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

  Widget _buildKlineTypeTabs() {
    return TextRadioButtonGroup(
      options: ["日K", "周K", "月K", "季K", "年K", "分时", "五日"],
      onChanged: (value) {
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
        widgets.add(
          MinuteAmountIndicator(
            minuteKlines: klineState.minuteKlines,
            klineType: klineState.klineType,
            crossLineIndex: klineState.crossLineIndex,
          ),
        );
      } else if (type == UiIndicatorType.minuteVolume ||
          type == UiIndicatorType.fiveDayMinuteVolume) {
        widgets.add(
          MinuteVolumeIndicator(
            minuteKlines: klineState.minuteKlines,
            klineType: klineState.klineType,
            crossLineIndex: klineState.crossLineIndex,
          ),
        );
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

    klineState.width = size.width;
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
    return klineType.isMinuteType ? klineState.minuteKlines : klineState.klines;
  }

  void _onKlineTypeChanged(String value) async {
    klineState.klineType = klineTypeMap[value]!;
    await loadKlines();
    setState(() {});
  }

  void onKeyDownArrowLeft() {
    final index = klineState.crossLineIndex;
    final klineRng = klineState.klineRng!;
    if (index == -1) {
      // 如果十字线未设置，默认设置为最后一根K线
      klineState.crossLineIndex = klineState.klines.length - 1;
    } else if (index == klineState.klineRng!.begin && klineRng.begin > 0) {
      klineState.klineRng!.begin -= 1;
      klineState.klineRng!.end -= 1;
      klineState.crossLineIndex -= 1;
    } else {
      klineState.crossLineIndex -= 1; // 向左移动十字线
    }
    setState(() {});
  }

  void onKeyDownArrowRight() {
    final index = klineState.crossLineIndex;
    final klineRng = klineState.klineRng!;
    if (index == -1) {
      // 如果十字线未设置，默认设置为最后一根K线
      klineState.crossLineIndex = klineState.klines.length - 1;
    } else if (index == klineState.klineRng!.end && klineRng.end < klineState.klines.length - 1) {
      // 如果十字线在可视范围的最后一根K线上，向右移动时需要扩展可视范围
      klineState.klineRng!.begin += 1;
      klineState.klineRng!.end += 1;
      klineState.crossLineIndex += 1;
    } else if (index >= klineState.klines.length - 1) {
      return; // 已经是最后一根K线了,界面不需要刷新
    } else {
      klineState.crossLineIndex += 1; // 向右移动十字线
    }
    setState(() {});
  }

  void detectKeyArrowLeftDown() {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed.contains(
      LogicalKeyboardKey.arrowLeft,
    );
    if (!pressed) {
      _holdTimer?.cancel();
    } else {
      _focusNode.requestFocus(); // 保持焦点
      onKeyDownArrowLeft();
    }
  }

  void detectKeyArrowRightDown() {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed.contains(
      LogicalKeyboardKey.arrowRight,
    );
    if (!pressed) {
      _holdTimer?.cancel();
    } else {
      _focusNode.requestFocus(); // 保持焦点
      onKeyDownArrowRight();
    }
  }

  // 支持鼠标上/下/左/右方向键进行缩放
  KeyEventResult _onKeyEvent(FocusNode focosNode, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        onKeyDownArrowLeft();
        _holdTimer?.cancel();
        _holdTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
          detectKeyArrowLeftDown();
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        onKeyDownArrowRight();
        _holdTimer?.cancel();
        _holdTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
          detectKeyArrowRightDown();
        });
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
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _focusNode.requestFocus(); // 保持焦点
        _holdTimer?.cancel();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _focusNode.requestFocus(); // 保持焦点
        _holdTimer?.cancel();
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
    final index = (localPosition.dx / klineState.klineWidth).floor();
    klineState.crossLineIndex = index + klineState.klineRng!.begin;
    setState(() {});
  }

  // 鼠标移动的时候需要动态绘制十字光标
  void _onMouseMove(PointerHoverEvent event) {}

  void _onMouseScroll(PointerEvent event) {
    if (event is PointerScrollEvent) {
      setState(() {});
    }
  }

  void logError(String s, {required Object error, required StackTrace stackTrace}) {}

  // 父子组件间通信
  // 1. 父组件通过构造函数传递数据给子组件
  // 2. 子组件通过回调函数将数据传递给父组件
  // 定义回调函数，用于子组件修改状态
  void notifyUpdate(UiKlineRange range) {
    setState(() {
      klineState.klineRng = range;
    });
  }

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

  // 实现缩放逻辑，显示的K线数量变多
  void zoomOut() {
    int crossLineIndex = klineState.crossLineIndex;
    UiKlineRange klineRng = klineState.klineRng!;
    if (crossLineIndex == -1) {
      crossLineIndex = klineState.klines.length - 1; // 缩小中心为最右边K线
    }
    // 可见K线数量大于等于总K线数量，不再缩小
    if (klineState.visibleKlineCount >= klineState.klines.length - 1) {
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
    if (klineRng.end >= klineState.klines.length - 1) {
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
    Size size = Size(klineState.width, klineState.klineChartHeight);
    if (klineState.klines.isEmpty) {
      return;
    }
    List<UiKline> klines = klineState.klines;
    double klineWidth;
    int klineInnerWidth;
    if (klines.length < 20) {
      klineWidth = 10;
      klineState.visibleKlineCount = klines.length;
      klineInnerWidth = 7;
    } else {
      klineWidth = (size.width / klineState.visibleKlineCount).floor().toDouble();
      klineInnerWidth = (klineWidth * 0.8).floor();
      if (klineWidth > 1 && klineInnerWidth % 2 == 0) {
        klineInnerWidth = klineInnerWidth;
        klineInnerWidth -= 1;
        if (klineInnerWidth < 1) {
          klineInnerWidth = 1;
        }
      }
      if (klineInnerWidth < 1) {
        klineInnerWidth = 1;
      }
      if (klineWidth < 1) {
        klineWidth = 1;
      }
    }
    debugPrint(
      "window Size: ${size.width}, klineWidth:$klineWidth, klineInnerWidth: $klineInnerWidth, visibleKlineCount: ${klineState.visibleKlineCount}",
    );
    klineState.klineWidth = klineWidth;
    klineState.klineInnerWidth = klineInnerWidth.toDouble();

    // 根据K线宽度计算起始坐标和放大坐标
    UiKlineRange klineRng = UiKlineRange(begin: 0, end: 0);
    klineRng.begin = klines.length - klineState.visibleKlineCount;
    klineRng.end = klines.length - 1;
    if (klineRng.begin < 0) {
      klineRng.begin = 0;
    }
    klineState.klineRng = klineRng;
  }
}
