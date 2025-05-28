// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/kline_ctrl/kline_ctrl.dart
// Purpose:     kline chart painter
// Author:      songhuabiao
// Created:     2025-05-22 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:irich/components/indicators/amount_indicator.dart';
import 'package:irich/components/indicators/minute_amount_indicator.dart';
import 'package:irich/components/indicators/minute_volume_indicator.dart';
import 'package:irich/components/indicators/turnoverrate_indicator.dart';
import 'package:irich/components/indicators/volume_indicator.dart';
import 'package:irich/components/kline_ctrl/kline_chart.dart';
import 'package:irich/components/text_radio_button_group.dart';
import 'package:irich/store/store_klines.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/utils/rich_result.dart';

class KlineState {
  String shareCode; // 股票代码
  KlineType type = KlineType.day; // 当前绘制的K线类型
  late List<UiKline> klines; // 前复权日K线数据
  late List<MinuteKline> minuteKlines; // 分时K线数据
  late UiKlineRange klineRng; // 可视K线范围
  late List<ShareEmaCurve> emaCurves; // EMA曲线数据
  late List<List<UiIndicator>> indicators; // 0:日/周/月/季/年K线技术指标列表,1:分时图技术指标列表,2:五日分时图技术指标列表
  late int visibleIndicatorIndex; // 需要显示的技术指标索引
  late int crossLineIndex; // 十字线位置
  late double klineWidth; // K线宽度
  late double klineInnerWidth; // K线内部宽度
  late int visibleKlineCount; // 可视区域K线数量

  KlineState({
    required this.shareCode,
    required this.type,
    required this.klines,
    required this.minuteKlines,
    required this.klineRng,
    required this.emaCurves,
    required this.indicators,
    required this.visibleIndicatorIndex,
    required this.crossLineIndex,
    required this.klineWidth,
    required this.klineInnerWidth,
    required this.visibleKlineCount,
  });

  // 深拷贝方法（可选）
  KlineState copyWith({
    String? shareCode,
    KlineType? type,
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
  }) {
    return KlineState(
      shareCode: shareCode ?? this.shareCode,
      type: type ?? this.type,
      klines: klines ?? this.klines,
      minuteKlines: minuteKlines ?? this.minuteKlines,
      klineRng: klineRng ?? this.klineRng,
      emaCurves: emaCurves ?? this.emaCurves,
      indicators: indicators ?? this.indicators,
      visibleIndicatorIndex: visibleIndicatorIndex ?? this.visibleIndicatorIndex,
      crossLineIndex: crossLineIndex ?? this.crossLineIndex,
      klineWidth: klineWidth ?? this.klineWidth,
      klineInnerWidth: klineInnerWidth ?? this.klineInnerWidth,
      visibleKlineCount: visibleKlineCount ?? this.visibleKlineCount,
    );
  }
}

class KlineCtrl extends StatefulWidget {
  const KlineCtrl({super.key});
  @override
  State<KlineCtrl> createState() => _KlineCtrlState();
}

class _KlineCtrlState extends State<KlineCtrl> {
  int activeKlineType = 1;
  late KlineState klineState;
  final FocusNode _focusNode = FocusNode();

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
  // 日/周/月/季/年K线的技术指标附图
  static const Map<String, UiIndicatorType> indicatorKline = {
    "成交量": UiIndicatorType.volume,
    "成交额": UiIndicatorType.amount,
    "换手率": UiIndicatorType.turnoverRate,
  };
  // 分时图技术指标附图
  static const Map<String, UiIndicatorType> indicatorMinute = {
    "分时成交量": UiIndicatorType.minuteVolume,
    "分时成交额": UiIndicatorType.minuteAmount,
  };
  // 五日分时图技术指标附图
  static const Map<String, UiIndicatorType> indicatorFiveDay = {
    "五日分时成交量": UiIndicatorType.fiveDayMinuteVolume,
    "五日分时成交额": UiIndicatorType.fiveDayMinuteAmount,
  };
  // 获取当前页面显示的技术指标附图
  Map<String, UiIndicatorType> getIndicators(KlineType klineType) {
    if (klineType == KlineType.day ||
        klineType == KlineType.week ||
        klineType == KlineType.month ||
        klineType == KlineType.quarter ||
        klineType == KlineType.year) {
      return indicatorKline;
    } else if (klineType == KlineType.minute) {
      return indicatorMinute;
    } else {
      return indicatorFiveDay;
    }
  }

  @override
  void initState() async {
    super.initState();
    await loadKlines();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Listener(
        onPointerSignal: _handleScroll,
        onPointerHover: _handleMouseMove,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          child: Transform.scale(
            scale: 1.0,
            child: Row(
              children: [
                // K线分组
                TextRadioButtonGroup(
                  options: ["日K", "周K", "月K", "季K", "年K", "分时", "五日"],
                  onChanged: (value) {
                    _onKlineTypeChanged(value);
                  },
                ),
                // EMA加权平均线
                SizedBox(
                  height: 20,
                  child: Column(children: _buildEmaCurveButtons(context, emaCurveMap)),
                ),
                // K线主图
                KlineChart(shareCode: klineState.shareCode),
                // 技术指标图
                ..._buildIndicators(context, klineState, getIndicators(klineState.type)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 加载K线数据
  Future<bool> loadKlines() async {
    try {
      final store = StoreKlines();
      final result = await _queryKlines(store, klineState.shareCode, klineState.type);
      return result.ok();
    } catch (e) {
      logError('Failed to load klines', error: e, stackTrace: StackTrace.current);
      return false;
    }
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

  List<dynamic> _getKlinesListForType(KlineType type) {
    return type.isMinuteType ? klineState.minuteKlines : klineState.klines;
  }

  void _onKlineTypeChanged(String value) async {
    klineState.type = klineTypeMap[value]!;
    await loadKlines();
    setState(() {});
  }

  // 支持鼠标上/下/左/右方向键进行缩放
  void _handleKeyEvent(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setState(() {});
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setState(() {});
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {});
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {});
    }
  }

  // 用户单击鼠标的时候也需要记住单击位置所在的K线下标，以此为中心点进行缩放
  void _handleTapDown(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    // 计算点击的K线索引
    final index = (localPosition.dx / klineState.klineWidth).floor();
    klineState.crossLineIndex = index;
    setState(() {});
  }

  // 鼠标移动的时候需要动态绘制十字光标
  void _handleMouseMove(PointerHoverEvent event) {}

  void _handleScroll(PointerEvent event) {
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

  void onKeyEvent(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      setState(() {});
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      setState(() {});
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {});
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {});
    }
  }

  void onMouseMove(PointerHoverEvent event) {}

  void onMouseScroll(PointerEvent event) {
    if (event is PointerScrollEvent) {
      if (event.scrollDelta.dy > 0) {
      } else {}
    }
  }

  // 绘制EMA曲线按钮组
  List<Widget> _buildEmaCurveButtons(BuildContext context, emaCurveMap) {
    List<Widget> widgets = [];
    for (final ema in emaCurveMap) {
      Color emaColor = _getEmaColor(ema.value);
      TextButton button = TextButton(
        style: TextButton.styleFrom(foregroundColor: emaColor),
        onPressed: () => {},
        child: Text(ema.key),
      );
      widgets.add(button);
    }

    return widgets;
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
  List<Widget> _buildIndicators(
    BuildContext context,
    KlineState klineState,
    Map<String, UiIndicatorType> indicatorMap,
  ) {
    List<Widget> widgets = [];
    for (final indicator in indicatorMap.entries) {
      if (indicator.value == UiIndicatorType.amount) {
        widgets.add(
          AmountIndicator(
            klines: klineState.klines,
            klineRange: klineState.klineRng,
            klineWidth: klineState.klineWidth,
            klineInnerWidth: klineState.klineInnerWidth,
            crossLineIndex: klineState.crossLineIndex,
            height: 100,
          ),
        );
      } else if (indicator.value == UiIndicatorType.volume) {
        widgets.add(
          VolumeIndicator(
            klines: klineState.klines,
            klineRange: klineState.klineRng,
            klineWidth: klineState.klineWidth,
            klineInnerWidth: klineState.klineInnerWidth,
            crossLineIndex: klineState.crossLineIndex,
            height: 100,
          ),
        );
      } else if (indicator.value == UiIndicatorType.turnoverRate) {
        widgets.add(
          TurnoverRateIndicator(
            klines: klineState.klines,
            klineRange: klineState.klineRng,
            klineWidth: klineState.klineWidth,
            klineInnerWidth: klineState.klineInnerWidth,
            crossLineIndex: klineState.crossLineIndex,
            height: 100,
          ),
        );
      } else if (indicator.value == UiIndicatorType.minuteAmount) {
        widgets.add(
          MinuteAmountIndicator(
            minuteKlines: klineState.minuteKlines,
            klineType: klineState.type,
            crossLineIndex: klineState.crossLineIndex,
          ),
        );
      } else if (indicator.value == UiIndicatorType.minuteVolume) {
        widgets.add(
          MinuteVolumeIndicator(
            minuteKlines: klineState.minuteKlines,
            klineType: klineState.type,
            crossLineIndex: klineState.crossLineIndex,
          ),
        );
      } else if (indicator.value == UiIndicatorType.fiveDayMinuteAmount) {
        widgets.add(
          MinuteAmountIndicator(
            minuteKlines: klineState.minuteKlines,
            klineType: klineState.type,
            crossLineIndex: klineState.crossLineIndex,
          ),
        );
      } else if (indicator.value == UiIndicatorType.fiveDayMinuteVolume) {
        widgets.add(
          MinuteVolumeIndicator(
            minuteKlines: klineState.minuteKlines,
            klineType: klineState.type,
            crossLineIndex: klineState.crossLineIndex,
          ),
        );
      }
    }
    return widgets;
  }
}
