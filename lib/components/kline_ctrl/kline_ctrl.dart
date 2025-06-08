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
import 'package:irich/components/indicators/boll_indicator.dart';
import 'package:irich/components/indicators/kdj_indicator.dart';
import 'package:irich/components/indicators/macd_indicator.dart';
import 'package:irich/components/indicators/minute_amount_indicator.dart';
import 'package:irich/components/indicators/minute_volume_indicator.dart';
import 'package:irich/components/indicators/turnoverrate_indicator.dart';
import 'package:irich/components/indicators/volume_indicator.dart';
import 'package:irich/components/kline_ctrl/cross_line_chart.dart';
import 'package:irich/components/kline_ctrl/kline_chart.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/components/rich_radio_button_group.dart';
import 'package:irich/formula/formula_boll.dart';
import 'package:irich/formula/formula_ema.dart';
import 'package:irich/formula/formula_kdj.dart';
import 'package:irich/formula/formula_macd.dart';
import 'package:irich/store/store_klines.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/theme/stock_colors.dart';
import 'package:irich/utils/rich_result.dart';

class KlineCtrl extends StatefulWidget {
  final Share share;
  const KlineCtrl({super.key, required this.share});
  @override
  State<KlineCtrl> createState() => _KlineCtrlState();
}

class _KlineCtrlState extends State<KlineCtrl> {
  late KlineCtrlState klineCtrlState;
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

  // 指标附图高度动态比例(最多4个指标附图)
  static const Map<int, double> chartHeightMap = {
    0: 1, // K线主图+0个指标附图
    1: 0.7, // K线主图+1个指标附图
    2: 0.6, // K线主图+2个指标附图
    3: 0.5, // K线主图+3个指标附图
    4: 0.4, // K线主图+4个指标附图
  };

  // 技术指标映射关系图
  static final indicatorCalculators = {
    UiIndicatorType.macd: FormulaMacd.calculate,
    UiIndicatorType.kdj: FormulaKdj.calculate,
    UiIndicatorType.boll: FormulaBoll.calculate,
  };

  static final indicatorBuilders =
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

  @override
  void initState() {
    super.initState();
    klineCtrlState = KlineCtrlState(share: widget.share, klineType: KlineType.day);
    klineCtrlState.klineStep = 7;
    klineCtrlState.klineWidth = 5;
    _focusNode = FocusNode();
    _focusNode.requestFocus();
    loadKlines(); // 加载K线数据
  }

  // 加载K线数据
  Future<void> loadKlines() async {
    try {
      final store = StoreKlines();
      final result = await _queryKlines(store, klineCtrlState.share.code, klineCtrlState.klineType);
      if (!result.ok()) {
        debugPrint("数据加载失败!,${klineCtrlState.klineType.name}");
        return;
      }
      // 添加 EMA 曲线的时候会自动计算相关数据
      KlineType klineType = klineCtrlState.klineType;
      if (klineType == KlineType.day ||
          klineType == KlineType.week ||
          klineType == KlineType.month ||
          klineType == KlineType.quarter ||
          klineType == KlineType.year) {
        klineCtrlState.emaCurves.clear();
        initKlineRange(); // 初始化可见K线范围
        addEmaCurve(10, Color.fromARGB(255, 255, 255, 255));
        addEmaCurve(20, Color.fromARGB(255, 239, 72, 111));
        addEmaCurve(30, Color.fromARGB(255, 255, 159, 26));
        addEmaCurve(60, Color.fromARGB(255, 201, 243, 240));
        addEmaCurve(99, Color.fromARGB(255, 255, 0, 255));
        addEmaCurve(255, Color.fromARGB(255, 255, 255, 0));
        addEmaCurve(905, Color.fromARGB(255, 0, 255, 0));
      }
      initIndicators(); // 初始化附图指标
      if (klineCtrlState.crossLineMode == CrossLineMode.followCursor) {
        updateCrossLine(klineCtrlState.crossLineFollowCursorPos);
      }
      setState(() {});
    } catch (e, stackTrace) {
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      logError('Failed to load klines', error: e, stackTrace: stackTrace);
    }
  }

  // 初始化可见K线范围和数量
  void initKlineRange() {
    if (klineCtrlState.klines.length < 120) {
      klineCtrlState.visibleKlineCount = klineCtrlState.klines.length;
      klineCtrlState.klineRng!.begin = 0;
      klineCtrlState.klineRng!.end = klineCtrlState.klines.length - 1;
    } else {
      klineCtrlState.visibleKlineCount = 120; // 默认显示120根K线
      klineCtrlState.klineRng!.begin =
          klineCtrlState.klines.length - klineCtrlState.visibleKlineCount;
      if (klineCtrlState.klineRng!.begin < 0) {
        klineCtrlState.klineRng!.begin = 0;
      }
      klineCtrlState.klineRng!.end = klineCtrlState.klines.length - 1;
    }
    calcKlineRngMinMaxPrice();
  }

  // 初始化附图指标，有可能需要从文件中加载
  void initIndicators() {
    final indicators = [
      [
        UiIndicator(type: UiIndicatorType.amount),
        // UiIndicator(type: UiIndicatorType.volume),
        // UiIndicator(type: UiIndicatorType.turnoverRate),
        UiIndicator(type: UiIndicatorType.macd),
        UiIndicator(type: UiIndicatorType.kdj),
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
    final klineType = klineCtrlState.klineType;
    if (klineType == KlineType.day ||
        klineType == KlineType.week ||
        klineType == KlineType.month ||
        klineType == KlineType.quarter ||
        klineType == KlineType.year) {
      klineCtrlState.indicators = indicators[0];
      klineCtrlState.dynamicIndicators = indicators[0];
      for (final indicator in klineCtrlState.indicators) {
        final calculator = indicatorCalculators[indicator.type];
        if (calculator == null) {
          continue;
        }
        final result = calculator(klineCtrlState.klines, {});
        initIndicatorData(indicator.type, result);
      }
    } else if (klineType == KlineType.minute) {
      klineCtrlState.indicators = indicators[1];
    } else if (klineType == KlineType.fiveDay) {
      klineCtrlState.indicators = indicators[2];
    }
  }

  // 填充技术指标计算结果
  void initIndicatorData(UiIndicatorType type, Map<String, List<double>> value) {
    switch (type) {
      case UiIndicatorType.macd:
        {
          klineCtrlState.macd = value;
          break;
        }
      case UiIndicatorType.kdj:
        {
          klineCtrlState.kdj = value;
          break;
        }
      case UiIndicatorType.boll:
        {
          klineCtrlState.boll = value;
          break;
        }
      default:
        debugPrint('未知指标类型: $type');
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
    final stockColors = Theme.of(context).extension<StockColors>()!;
    return Focus(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: MouseRegion(
        onHover: _onPointerHover, // 解决Listerner的onPointerHover方法无法触发鼠标移动的bug
        child: Listener(
          onPointerSignal: _onMouseScroll,
          child: GestureDetector(onTapDown: _onTapDown, child: buildKlineCtrl(stockColors)),
        ),
      ),
    );
  }

  Widget buildKlineCtrl(StockColors stockColors) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // final parentWidth = constraints.maxWidth; // 父容器可用宽度
        Size size = Size(constraints.maxWidth, constraints.maxHeight);
        updateSize(size); // 计算K线图宽高,当前显示的K线图范围
        return Stack(
          children: [
            Column(
              children: [
                // K线类型切换
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [_buildKlineName(), _buildKlineTypeTabs()]),
                    // 自选按钮
                    _buildFavoriteButton(klineCtrlState.share.isFavorite, stockColors),
                  ],
                ),
                // K线主图
                KlineChart(
                  klineCtrlState: klineCtrlState,
                  stockColors: stockColors,
                  onToggleEmaCurve: toggleEmaCurve,
                ),
                // 技术指标图
                ..._buildIndicators(context, klineCtrlState, stockColors),
              ],
            ),
            // 十字线
            Positioned(
              left: klineCtrlState.klineChartLeftMargin,
              top: klineCtrlState.klineCtrlTitleBarHeight * 2 - KlineCtrlLayout.titleBarMargin,
              child: CrossLineChart(klineCtrlState: klineCtrlState, stockColors: stockColors),
            ),
          ],
        );
      },
    );
  }

  void updateSize(Size size) {
    double ratio = 1;
    if (klineCtrlState.indicators.length <= 4) {
      ratio = chartHeightMap[klineCtrlState.indicators.length]!;
    }
    klineCtrlState.klineCtrlWidth = size.width;
    klineCtrlState.klineCtrlHeight = size.height;
    klineCtrlState.klineChartWidth =
        size.width - klineCtrlState.klineChartLeftMargin - klineCtrlState.klineChartRightMargin;
    double height = size.height - klineCtrlState.klineCtrlTitleBarHeight;
    if (!klineCtrlState.klineType.isMinuteType) {
      height = height - klineCtrlState.klineCtrlTitleBarHeight + KlineCtrlLayout.titleBarMargin;
    }
    klineCtrlState.klineChartHeight = (height * ratio).floorToDouble();
    double scaleIndicator = (1 - ratio) / klineCtrlState.indicators.length;
    klineCtrlState.indicatorChartHeight =
        klineCtrlState.indicators.isEmpty ? 0 : height * scaleIndicator;

    calcVisibleKlineWidth();
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
    return RichRadioButtonGroup(
      options: ["日K", "周K", "月K", "季K", "年K", "分时", "五日"],
      onChanged: (value) {
        debugPrint("onclicked ：$value");
        _onKlineTypeChanged(value);
      },
      height: KlineCtrlLayout.titleBarHeight,
    );
  }

  // 添加股票到自选池
  void _onToggleFavoriteButton() {
    klineCtrlState.share.isFavorite = !klineCtrlState.share.isFavorite;
    StoreQuote.addFavoriteShare(klineCtrlState.share.code);
    debugPrint("isFavorite: ${klineCtrlState.share.isFavorite}");
    setState(() {});
  }

  // 构建自选按钮
  Widget _buildFavoriteButton(bool isFavorite, StockColors stockColors) {
    return // 自选按钮
    MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _onToggleFavoriteButton,
        child: Row(
          children: [
            Icon(isFavorite ? Icons.remove : Icons.add, size: 18, color: stockColors.hilight),
            Text(
              "自选",
              style: TextStyle(
                backgroundColor: Colors.transparent,
                color: stockColors.hilight,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // 绘制技术指标附图
  List<Widget> _buildIndicators(
    BuildContext context,
    KlineCtrlState klienState,
    StockColors stockColors,
  ) {
    final indicators = klineCtrlState.indicators;
    if (indicators.isEmpty) {
      return [];
    }
    List<Widget> widgets = [];

    for (final indicator in indicators) {
      final builder = indicatorBuilders[indicator.type];
      if (builder == null) continue;
      widgets.add(builder(klineCtrlState, stockColors));
    }

    return widgets;
  }

  Future<RichResult> _queryKlines(StoreKlines store, String stockCode, KlineType type) async {
    final klines = _getKlinesListForType(type);
    klines.clear();
    return switch (type) {
      KlineType.day => store.queryDayKlines(stockCode, klines as List<UiKline>),
      KlineType.minute => store.queryMinuteKlines(stockCode, klines as List<MinuteKline>),
      KlineType.week => store.queryWeekKlines(stockCode, klines as List<UiKline>),
      KlineType.month => store.queryMonthKlines(stockCode, klines as List<UiKline>),
      KlineType.quarter => store.queryQuarterKlines(stockCode, klines as List<UiKline>),
      KlineType.year => store.queryYearKlines(stockCode, klines as List<UiKline>),
      KlineType.fiveDay => store.queryFiveDayMinuteKlines(stockCode, klines as List<MinuteKline>),
      _ => error(RichStatus.shareNotExist, desc: 'Unsupported KlineType: $type'),
    };
  }

  List<dynamic> _getKlinesListForType(KlineType klineType) {
    if (klineType.isMinuteType) {
      if (klineType == KlineType.minute) {
        return klineCtrlState.minuteKlines;
      } else {
        return klineCtrlState.fiveDayMinuteKlines;
      }
    } else {
      return klineCtrlState.klines;
    }
  }

  void _onKlineTypeChanged(String value) async {
    klineCtrlState.klineType = klineTypeMap[value]!;
    await loadKlines();
    updateCrossLine(klineCtrlState.crossLineFollowCursorPos);
    setState(() {});
  }

  void onKeyDownArrowLeft() {
    int crossLineFollowKlineIndex = klineCtrlState.crossLineFollowKlineIndex;
    UiKlineRange klineRng = klineCtrlState.klineRng!;
    if (crossLineFollowKlineIndex == -1) {
      // 如果十字线未设置，默认设置为最后一根K线
      crossLineFollowKlineIndex = klineCtrlState.klines.length - 1;
    } else if ((crossLineFollowKlineIndex == klineRng.begin) && (klineRng.begin > 0)) {
      klineRng.begin -= 1;
      klineRng.end -= 1;
      crossLineFollowKlineIndex -= 1;
      calcKlineRngMinMaxPrice();
    } else {
      crossLineFollowKlineIndex -= 1; // 向左移动十字线
    }
    klineCtrlState = klineCtrlState.copyWith(
      klineRng: klineRng,
      crossLineFollowKlineIndex: crossLineFollowKlineIndex,
      crossLineMode: CrossLineMode.followKline,
    );
    setState(() {});
  }

  void onKeyDownArrowRight() {
    final crossLineFollowKlineIndex = klineCtrlState.crossLineFollowKlineIndex;
    final klineRng = klineCtrlState.klineRng!;
    if (crossLineFollowKlineIndex == -1) {
      // 如果十字线未设置，默认设置为最后一根K线
      klineCtrlState.crossLineFollowKlineIndex = klineCtrlState.klines.length - 1;
    } else if ((crossLineFollowKlineIndex >= klineCtrlState.klineRng!.end) &&
        (klineRng.end < klineCtrlState.klines.length - 1)) {
      // 如果十字线在可视范围的最后一根K线上，向右移动时需要扩展可视范围
      klineCtrlState.klineRng!.begin += 1;
      klineCtrlState.klineRng!.end += 1;
      klineCtrlState.crossLineFollowKlineIndex += 1;
      calcKlineRngMinMaxPrice();
    } else if (crossLineFollowKlineIndex >= klineCtrlState.klines.length - 1) {
      return; // 已经是最后一根K线了,界面不需要刷新
    } else {
      klineCtrlState.crossLineFollowKlineIndex += 1; // 向右移动十字线
    }
    klineCtrlState.crossLineMode = CrossLineMode.followKline;
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
        klineCtrlState.crossLineMode = CrossLineMode.none;
        klineCtrlState.crossLineFollowKlineIndex = -1; // 清除十字线
        klineCtrlState.crossLineFollowCursorPos = Offset.zero;
      } else if (event.logicalKey == LogicalKeyboardKey.home) {
        klineCtrlState.crossLineFollowKlineIndex = klineCtrlState.klineRng!.begin;
      } else if (event.logicalKey == LogicalKeyboardKey.end) {
        klineCtrlState.crossLineFollowKlineIndex = klineCtrlState.klineRng!.end;
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
    updateCrossLine(localPosition);
    setState(() {});
  }

  // 切换日/周/月/年K线时，需要重新计算十字线相对当前K线范围的位置，尤其是 crossLineFollowKlineIndex
  void updateCrossLine(Offset localPosition) {
    if ((localPosition.dx > klineCtrlState.klineChartLeftMargin) &&
        localPosition.dx < (klineCtrlState.klineChartLeftMargin + klineCtrlState.klineChartWidth)) {
      klineCtrlState.crossLineFollowKlineIndex = calcCrossLineFollowKlineIndex(localPosition);
      klineCtrlState.crossLineFollowCursorPos = localPosition;
      klineCtrlState.crossLineMode = CrossLineMode.followCursor;
    }
  }

  int calcCrossLineFollowKlineIndex(Offset localPosition) {
    final index = (localPosition.dx / klineCtrlState.klineStep).floor();
    return index + klineCtrlState.klineRng!.begin;
  }

  void _onPointerHover(PointerEvent event) {
    _onMouseMove(event.localPosition);
  }

  // 鼠标移动的时候需要动态绘制十字光标
  void _onMouseMove(Offset localPosition) {
    if ((localPosition.dx > klineCtrlState.klineChartLeftMargin) &&
        localPosition.dx < (klineCtrlState.klineChartLeftMargin + klineCtrlState.klineChartWidth)) {
      if (klineCtrlState.crossLineMode != CrossLineMode.none) {
        klineCtrlState.crossLineFollowCursorPos = localPosition;
        klineCtrlState.crossLineFollowKlineIndex = calcCrossLineFollowKlineIndex(localPosition);
        klineCtrlState.crossLineMode = CrossLineMode.followCursor;
      }
      setState(() {});
    }
  }

  // 鼠标滚轮事件处理,可以用来切换股票
  void _onMouseScroll(PointerEvent event) {
    if (event is PointerScrollEvent) {
      if (event.scrollDelta.dy > 0) {
      } else {}
      setState(() {});
    }
  }

  void logError(String s, {required Object error, required StackTrace stackTrace}) {}

  // 添加技术指标
  void addIndicator(UiIndicator indicator, int i) {
    klineCtrlState.dynamicIndicators.add(indicator);
  }

  // 添加EMA曲线
  bool addEmaCurve(int period, Color color) {
    if (klineCtrlState.emaCurves.length >= 8) {
      // 一个界面最多显示8条EMA平滑移动价格曲线
      return false;
    }

    ShareEmaCurve curve = ShareEmaCurve(color: color, period: period, visible: true, emaPrice: []);
    curve.emaPrice = FormulaEma.calc(klineCtrlState.klines, period);
    klineCtrlState.emaCurves.add(curve);
    calcKlineRngMinMaxPrice();
    // 刷新
    return true;
  }

  // 移除所有匹配指定周期的曲线
  bool removeEmaCurve(int period) {
    final originalLength = klineCtrlState.emaCurves.length;
    klineCtrlState.emaCurves.removeWhere((curve) => curve.period == period);
    bool result = klineCtrlState.emaCurves.length != originalLength;
    if (result) {
      calcKlineRngMinMaxPrice();
    }
    return result;
  }

  // 不显示EMA曲线
  bool toggleEmaCurve(int period) {
    final curves = klineCtrlState.emaCurves;
    bool bSuccess = false;
    for (final curve in curves) {
      if (curve.period == period) {
        curve.visible = !curve.visible;
        bSuccess = true;
      }
    }
    if (bSuccess) {
      klineCtrlState = klineCtrlState.copyWith(emaCurves: curves);
      calcKlineRngMinMaxPrice();
      setState(() {});
    }
    return bSuccess;
  }

  // 处理放大逻辑,可见的K线数量变少
  void zoomIn() {
    int crossLineFollowKlineIndex = klineCtrlState.crossLineFollowKlineIndex;
    UiKlineRange klineRng = klineCtrlState.klineRng!;
    if (crossLineFollowKlineIndex == -1) {
      crossLineFollowKlineIndex = klineCtrlState.klines.length - 1; // 放大中心为最右边K线
    }
    // 可见K线数量少于8，不再放大
    if (klineRng.end <= klineRng.begin + 8) {
      return;
    }

    // 计算放大中心两边的K线数量
    int leftKlineCount = crossLineFollowKlineIndex - klineRng.begin;
    int rightKlineCount = klineRng.end - crossLineFollowKlineIndex;
    // 取中心点左右两侧K线较多的一边进行延展，保住缩放中心的位置
    int count = leftKlineCount > rightKlineCount ? leftKlineCount : rightKlineCount;
    klineRng.begin = crossLineFollowKlineIndex - count ~/ 2;
    klineRng.end = crossLineFollowKlineIndex + count ~/ 2;

    // 左右边界处理
    if (klineRng.begin > klineRng.end) {
      klineRng.begin = klineRng.end - 8;
    }

    if (klineRng.begin < 0) {
      klineRng.begin = 0;
    }
    if (klineRng.end > klineCtrlState.klines.length - 1) {
      klineRng.end = klineCtrlState.klines.length - 1;
    }
    klineCtrlState = klineCtrlState.copyWith(
      klineRng: klineRng,
      visibleKlineCount: klineRng.end - klineRng.begin + 1,
      crossLineFollowKlineIndex: crossLineFollowKlineIndex,
      crossLineMode: CrossLineMode.followKline,
    );
    calcVisibleKlineWidth();
    calcKlineRngMinMaxPrice();
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
    int crossLineFollowKlineIndex = klineCtrlState.crossLineFollowKlineIndex;
    UiKlineRange klineRng = klineCtrlState.klineRng!;
    if (crossLineFollowKlineIndex == -1) {
      crossLineFollowKlineIndex = klineCtrlState.klines.length - 1; // 缩小中心为最右边K线
    }
    // 可见K线数量大于等于总K线数量，不再缩小
    if (klineCtrlState.visibleKlineCount == klineCtrlState.klines.length) {
      debugPrint("无法继续缩放了！");
      double klineStep = klineCtrlState.klineChartWidth / klineCtrlState.visibleKlineCount * 0.85;
      int klineWidth = (klineCtrlState.klineStep * 0.8).floor();
      klineWidth = _ensureKlineWidth(klineStep, klineWidth);
      klineCtrlState = klineCtrlState.copyWith(
        klineStep: klineStep,
        klineWidth: klineWidth.toDouble(),
      );
      calcKlineRngMinMaxPrice();
      return;
    }

    // 计算缩小中心两边的K线数量
    int leftKlineCount = crossLineFollowKlineIndex - klineRng.begin;
    int rightKlineCount = klineRng.end - crossLineFollowKlineIndex;
    // 取中心点左右两侧K线较多的一边进行收缩，保住缩放中心的地位
    int count = leftKlineCount > rightKlineCount ? leftKlineCount : rightKlineCount;
    klineRng.begin = crossLineFollowKlineIndex - count * 2;
    klineRng.end = crossLineFollowKlineIndex + count * 2;

    // 左右边界处理
    if (klineRng.begin < 0) {
      klineRng.begin = 0;
    }
    if (klineRng.end > klineCtrlState.klines.length - 1) {
      klineRng.end = klineCtrlState.klines.length - 1;
    }
    klineCtrlState = klineCtrlState.copyWith(
      klineRng: klineRng,
      visibleKlineCount: klineRng.end - klineRng.begin + 1,
      crossLineFollowKlineIndex: crossLineFollowKlineIndex,
      crossLineMode: CrossLineMode.followKline,
    );
    calcVisibleKlineWidth();
    calcKlineRngMinMaxPrice();
  }

  // 获取可见K线范围内的 最高价/最低价
  void calcKlineRngMinMaxPrice() {
    double min = double.infinity;
    double max = double.negativeInfinity;
    for (int i = klineCtrlState.klineRng!.begin; i <= klineCtrlState.klineRng!.end; i++) {
      if (klineCtrlState.klines[i].priceMin < min) {
        min = klineCtrlState.klines[i].priceMin;
      }
      if (klineCtrlState.klines[i].priceMax > max) {
        max = klineCtrlState.klines[i].priceMax;
      }
    }
    if (klineCtrlState.emaCurves.isNotEmpty) {
      for (final curve in klineCtrlState.emaCurves) {
        if (curve.visible) {
          for (int i = klineCtrlState.klineRng!.begin; i <= klineCtrlState.klineRng!.end; i++) {
            if (curve.emaPrice[i] < min) {
              min = curve.emaPrice[i];
            }
            if (curve.emaPrice[i] > max) {
              max = curve.emaPrice[i];
            }
          }
        }
      }
    }

    klineCtrlState.klineRngMinPrice = min;
    klineCtrlState.klineRngMaxPrice = max;
  }

  // 计算可视范围K线自适应宽度
  void calcVisibleKlineWidth() {
    Size size = Size(klineCtrlState.klineChartWidth, klineCtrlState.klineChartHeight);
    if (klineCtrlState.klines.isEmpty) {
      return;
    }
    double klineStep;
    int klineWidth;
    klineStep = size.width / klineCtrlState.visibleKlineCount;
    klineWidth = (klineStep * 0.8).floor();
    klineWidth = _ensureKlineWidth(klineStep, klineWidth);
    klineCtrlState.klineStep = klineStep;
    klineCtrlState.klineWidth = klineWidth.toDouble();
  }
}
