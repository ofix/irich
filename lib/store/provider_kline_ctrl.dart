// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/provider_kline_ctrl.dart
// Purpose:     kline ctrl provider
// Author:      songhuabiao
// Created:     2025-06-11 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/service/formula_engine/formula/formula_boll.dart';
import 'package:irich/service/formula_engine/formula/formula_ema.dart';
import 'package:irich/service/formula_engine/formula/formula_kdj.dart';
import 'package:irich/service/formula_engine/formula/formula_macd.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/service/trading_calendar.dart';
import 'package:irich/store/state_quote.dart';
import 'package:irich/store/store_klines.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/utils/rich_result.dart';

class KlineCtrlParams {
  final String shareCode;
  final KlineWndMode wndMode;
  final KlineType klineType;

  KlineCtrlParams({
    required this.shareCode,
    this.wndMode = KlineWndMode.full, // 类内定义默认值
    this.klineType = KlineType.day,
  });
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is KlineCtrlParams && shareCode == other.shareCode);

  @override
  int get hashCode => shareCode.hashCode;
}

final klineCtrlProvider = StateNotifierProvider<KlineCtrlNotifier, KlineCtrlState>((ref) {
  final notifier = KlineCtrlNotifier(
    ref: ref,
    shareCode: "",
    wndMode: KlineWndMode.full,
    klineType: KlineType.day,
  );
  // ✅ 关键修复：主动获取当前值并同步
  final currentCode = ref.read(currentShareCodeProvider);
  if (currentCode != "") {
    notifier.changeShareCode(currentCode);
  }

  // 监听全局股票代码变化
  ref.listen<String>(currentShareCodeProvider, (_, newCode) => notifier.changeShareCode(newCode));
  return notifier;
});

class KlineCtrlNotifier extends StateNotifier<KlineCtrlState> {
  // 技术指标映射关系图
  static final indicatorCalculators = {
    UiIndicatorType.macd: FormulaMacd.calculate,
    UiIndicatorType.kdj: FormulaKdj.calculate,
    UiIndicatorType.boll: FormulaBoll.calculate,
  };

  // 指标附图高度动态比例(最多4个指标附图)
  static const Map<int, double> chartHeightMap = {
    0: 1, // K线主图+0个指标附图
    1: 0.7, // K线主图+1个指标附图
    2: 0.6, // K线主图+2个指标附图
    3: 0.5, // K线主图+3个指标附图
    4: 0.4, // K线主图+4个指标附图
  };

  Ref ref;
  StoreKlines storeKlines = StoreKlines();
  Timer? _timer;

  KlineCtrlNotifier({
    required this.ref,
    required String shareCode,
    KlineWndMode wndMode = KlineWndMode.full,
    KlineType klineType = KlineType.day,
  }) : super(KlineCtrlState(shareCode: shareCode, wndMode: wndMode, klineType: klineType));
  // 切换股票代码的时候需要重新初始化
  void changeShareCode(String shareCode) async {
    Share? share = StoreQuote.query(shareCode);
    // 如果切换股票的时候，当前窗口是分时图或者5日分时图，则需要先加载日K线图
    // 因为分时窗口需要EMA价格数据，而EMA价格数据需要日K线图数据
    RichResult result;
    List<UiKline> klines = [];
    List<MinuteKline> minuteKlines = [];
    if (state.klineType.isMinuteType) {
      (result, klines) = await _queryKlines<UiKline>(
        store: storeKlines,
        shareCode: shareCode,
        klineType: KlineType.day,
      );
      if (!result.ok()) {
        debugPrint("Failed to load day Kline for $shareCode");
      }
      (result, minuteKlines) = await _queryKlines<MinuteKline>(
        store: storeKlines,
        shareCode: shareCode,
        klineType: state.klineType,
      );
      if (!result.ok()) {
        debugPrint("Failed to load minute Kline for $shareCode");
      }
    } else {
      (result, klines) = await _queryKlines<UiKline>(
        store: storeKlines,
        shareCode: shareCode,
        klineType: state.klineType,
      );
      if (!result.ok()) {
        debugPrint("Failed to load ${state.klineType.name} Kline for $shareCode");
      }
    }
    // 更新股票K线数据

    // 初始化技术指标附图
    List<UiIndicator> indicators = _initIndicators(state.klineType);
    // 初始化子控件宽高
    double ratio = 1;
    if (indicators.length <= 4) {
      ratio = chartHeightMap[indicators.length]!;
    }
    final klineChartWidth =
        state.klineCtrlWidth - state.klineChartLeftMargin - state.klineChartRightMargin;
    final klineChartHeight = _getKlineChartHeight(state.klineCtrlHeight, state.klineType, ratio);
    final indicatorChartHeight = _getIndicatorChartHeight(
      state.klineCtrlHeight,
      state.klineType,
      ratio,
      indicators.length,
    );
    final klineRng = _initKlineRng(klines);
    final visibleKlineCount = klineRng.end - klineRng.begin + 1;
    double klineStep = _calcVisibleKlineStep(visibleKlineCount, klineChartWidth);
    double klineWidth = _calcVisibleKlineWidth(klineStep);
    // 先初始化EMA曲线和EMA价格
    List<ShareEmaCurve> emaCurves = [];
    for (final setting in state.emaCurveSettings) {
      final curve = _initEmaCurve(setting.period, setting.color, klines);
      emaCurves.add(curve);
    }
    // 填充技术指标数据
    _calcIndicators(indicators, klines);
    // 初始化可见范围最高价/最低价
    final (klineRngMinPrice, klineRngMaxPrice) = _calcKlineRngMinMaxPrice(
      klineRng,
      klines,
      emaCurves,
    );

    debugPrint("++++++++++++++++++++++++++++++++++++++++++++");
    debugPrint("klineChartWidth = $klineChartWidth");
    debugPrint("klineCtrlHeight = ${state.klineCtrlHeight}");
    debugPrint("klineChartHeight = $klineChartHeight");
    debugPrint("indicatorChartHeight = $indicatorChartHeight");
    debugPrint("klineRng = $klineRng");
    debugPrint("klineStep = $klineStep");
    debugPrint("klineWidth = $klineWidth");
    debugPrint("emaCurves.length = ${emaCurves.length}");
    debugPrint("klineRngMinPrice = $klineRngMinPrice");
    debugPrint("klineRngMaxPrice = $klineRngMaxPrice");
    debugPrint("++++++++++++++++++++++++++++++++++++++++++++");

    state = state.copyWith(
      share: share,
      shareCode: shareCode,
      indicators: indicators,
      dynamicIndicators: indicators,
      klineChartWidth: klineChartWidth,
      klineChartHeight: klineChartHeight,
      indicatorChartHeight: indicatorChartHeight,
      klineRng: klineRng,
      visibleKlineCount: visibleKlineCount,
      klineStep: klineStep,
      klineWidth: klineWidth,
      emaCurves: emaCurves,
      klines: klines,
      minuteKlines: minuteKlines,
      klineRngMinPrice: klineRngMinPrice,
      klineRngMaxPrice: klineRngMaxPrice,
      crossLineFollowKlineIndex: -1, // 切换股票的时候 crossLineFolleKlineIndex 未同步更新，有可能超过当前K线数量,需要重置
      dataLoaded: true,
    );

    updateEmaPrices();

    // 如果是交易时段，需要定时刷新分时数据
    if (TradingCalendar().isTradingTime()) {
      startTimer();
    }
  }

  /// 获取分时K线数据的最高价
  /// 若列表为空则返回 0 表示无效值
  double getMaxMinuteKlinePrice(List<MinuteKline> klines) {
    if (klines.isEmpty) return 0;

    double max = klines[0].price;
    for (final kline in klines.skip(1)) {
      if (kline.price > max) max = kline.price;
    }
    return max;
  }

  /// 获取分时K线数据的最低价
  /// 若列表为空则返回 0 表示无效值
  double getMinMinuteKlinePrice(List<MinuteKline> klines) {
    if (klines.isEmpty) return 0;

    double min = klines[0].price;
    for (final kline in klines.skip(1)) {
      if (kline.price < min) min = kline.price;
    }
    return min;
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (state.shareCode.isEmpty) return; // 没有股票代码时不执行
      List<MinuteKline> minuteKlines = [];
      RichResult result;
      // 交易时间，如果是日/周/月/季/年的K线图，则必须请求分时数据
      if (state.klineType == KlineType.day ||
          state.klineType == KlineType.week ||
          state.klineType == KlineType.month ||
          state.klineType == KlineType.quarter ||
          state.klineType == KlineType.year ||
          state.klineType == KlineType.minute) {
        (result, minuteKlines) = await _queryKlines<MinuteKline>(
          store: storeKlines,
          shareCode: state.shareCode,
          klineType: KlineType.minute,
        );
        if (!result.ok()) {
          debugPrint("Failed to load minute Klines for ${state.shareCode}: ${result.desc}");
          return;
        }
        // 更新日K线的最后一条记录的最低价，最高价，最新价，成交量，成交额等
        if (minuteKlines.isNotEmpty) {
          double todayMinPrice = getMinMinuteKlinePrice(minuteKlines);
          double todayMaxPrice = getMaxMinuteKlinePrice(minuteKlines);
          BigInt todayVolume = minuteKlines.last.totalVolume;
          double todayAmount = minuteKlines.last.totalAmount;
          double todayChangeRate = minuteKlines.last.changeRate;
          if (state.klines.isNotEmpty) {
            // 更新日K线的最后一条记录，周/月/季/年的K线图需要额外处理
            final todayKline = state.klines.last;
            todayKline.priceMin = todayMinPrice; // 当日最低价
            todayKline.priceMax = todayMaxPrice; // 当日最高价
            todayKline.priceNow = minuteKlines.last.price; // 当日最新价
            todayKline.priceOpen =
                minuteKlines.first.price - minuteKlines.first.changeAmount; // 当日开盘价
            todayKline.priceClose = minuteKlines.last.price; // 当日收盘价
            todayKline.volume = todayVolume; // 当日成交量
            todayKline.amount = todayAmount; // 当日成交额
            todayKline.changeRate = todayChangeRate; // 当日换手率
          }
        }
      } else {
        (result, minuteKlines) = await _queryKlines<MinuteKline>(
          store: storeKlines,
          shareCode: state.shareCode,
          klineType: state.klineType,
        );
        if (!result.ok()) {
          debugPrint("Failed to load ${state.shareCode},${state.klineType}: ${result.desc}");
          return;
        }
      }
      state = state.copyWith(refreshCount: state.refreshCount + 1, minuteKlines: minuteKlines);
      // 检查交易时间是否结束
      if (!TradingCalendar().isTradingTime()) {
        _timer?.cancel(); // 停止定时器
        _timer = null;
      }
    });
  }

  void changeMinuteWndMode(MinuteKlineWndMode mode) {
    if (state.klineType.isMinuteType) {
      state = state.copyWith(minuteWndMode: mode);
    }
  }

  void updateEmaPrices() {
    int index = state.crossLineFollowKlineIndex;
    if (index == -1) {
      index = state.klines.length - 1;
    }
    Map<int, double> emaPrices = {};
    for (final curve in state.emaCurves) {
      emaPrices[curve.period] = curve.emaPrice[index];
    }
    ref.read(emaCurveProvider.notifier).update(emaPrices);
  }

  Future<(RichResult, List<T>)> _queryKlines<T>({
    required StoreKlines store,
    required String shareCode,
    required KlineType klineType,
  }) async {
    final queryFn = switch (klineType) {
      KlineType.day => store.queryDayKlines,
      KlineType.week => store.queryWeekKlines,
      KlineType.month => store.queryMonthKlines,
      KlineType.quarter => store.queryQuarterKlines,
      KlineType.year => store.queryYearKlines,
      KlineType.minute => store.queryMinuteKlines,
      KlineType.fiveDay => store.queryFiveDayMinuteKlines,
    };

    final result = await queryFn(shareCode);
    return (result.$1, result.$2 as List<T>);
  }

  void changeKlineType(KlineType klineType) {
    // 切换K线类型必须重新初始化附图指标个数和宽高，否则 flutter 渲染的时候会溢出
    List<UiIndicator> indicators = _initIndicators(klineType);
    // 初始化子控件宽高
    double ratio = 1;
    if (indicators.length <= 4) {
      ratio = chartHeightMap[indicators.length]!;
    }
    final klineChartWidth =
        state.klineCtrlWidth - state.klineChartLeftMargin - state.klineChartRightMargin;
    final klineChartHeight = _getKlineChartHeight(state.klineCtrlHeight, klineType, ratio);
    final indicatorChartHeight = _getIndicatorChartHeight(
      state.klineCtrlHeight,
      klineType,
      ratio,
      indicators.length,
    );

    state = state.copyWith(
      klineType: klineType,
      klineChartWidth: klineChartWidth,
      klineChartHeight: klineChartHeight,
      indicatorChartHeight: indicatorChartHeight,
      indicators: indicators,
      dynamicIndicators: indicators,
      dataLoaded: false,
    );

    changeShareCode(state.shareCode);
  }

  // 切换K线类别的时候，需要重新计算EMA曲线价格
  void updateAllEmaCurves() {
    List<ShareEmaCurve> emaCurves = [];
    for (final curve in state.emaCurves) {
      ShareEmaCurve newCurve = ShareEmaCurve(
        period: curve.period,
        color: curve.color,
        visible: curve.visible,
        emaPrice: [],
      );
      newCurve.emaPrice = FormulaEma.calc(state.klines, curve.period);
    }
    state = state.copyWith(emaCurves: emaCurves);
  }

  ShareEmaCurve _initEmaCurve(int period, Color color, List<UiKline> klines) {
    final emaValues = FormulaEma.calc(klines, period);
    // 3. 创建新曲线（使用const构造器如果可能）
    return ShareEmaCurve(
      color: color,
      period: period,
      visible: true,
      emaPrice: emaValues, // 直接初始化避免二次赋值
    );
  }

  // 添加EMA曲线
  void addEmaCurve(int period, Color color) {
    // 1. 前置条件检查
    if (state.emaCurves.length >= 8 || state.emaCurves.any((c) => c.period == period)) {
      return; // 已达上限或已存在相同周期曲线
    }

    // 2. 计算EMA值（缓存klines引用避免多次访问state）
    final klines = state.klines;
    if (klines.isEmpty) return;

    final emaValues = FormulaEma.calc(klines, period);

    // 3. 创建新曲线（使用const构造器如果可能）
    final newCurve = ShareEmaCurve(
      color: color,
      period: period,
      visible: true,
      emaPrice: emaValues, // 直接初始化避免二次赋值
    );

    // 4. 合并计算和状态更新
    final newCurves = [...state.emaCurves, newCurve];
    final (minPrice, maxPrice) = _calcKlineRngMinMaxPrice(state.klineRng, klines, newCurves);

    // 5. 单次不可变更新
    state = state.copyWith(
      emaCurves: newCurves,
      klineRngMinPrice: minPrice,
      klineRngMaxPrice: maxPrice,
    );
  }

  // 移除所有匹配指定周期的曲线
  void removeEmaCurve(int period) {
    // 使用where过滤更简洁
    final newEmaCurves = state.emaCurves.where((c) => c.period != period).toList();

    // 如果没有变化则提前返回
    if (newEmaCurves.length == state.emaCurves.length) return;

    final (klineRngMinPrice, klineRngMaxPrice) = _calcKlineRngMinMaxPrice(
      state.klineRng,
      state.klines,
      state.emaCurves,
    );

    // 合并为单次状态更新
    state = state.copyWith(
      emaCurves: newEmaCurves,
      klineRngMinPrice: klineRngMinPrice,
      klineRngMaxPrice: klineRngMaxPrice,
    );
  }

  // EMA曲线显示或隐藏
  void toggleEmaCurve(int period) {
    // 1. 创建新的 ShareEmaCurve 列表（确保每个修改的元素是新对象）
    final newCurves =
        state.emaCurves.map((curve) {
          if (curve.period == period) {
            return curve.copyWith(
              visible: !curve.visible,
            ); // ShareEmaCurve 必须是不可变的,否则RiverPod 无法检测改变
          }
          return curve; // 未修改的元素可以直接复用（无需新引用）
        }).toList(); // 转换为新列表

    // 2. 计算价格范围（使用更新后的 newCurves）
    final (klineRngMinPrice, klineRngMaxPrice) = _calcKlineRngMinMaxPrice(
      state.klineRng,
      state.klines,
      newCurves,
    );

    // 3. 更新状态（确保所有层级都是新引用）
    state = state.copyWith(
      emaCurves: newCurves, // 新列表
      klineRngMinPrice: klineRngMinPrice,
      klineRngMaxPrice: klineRngMaxPrice,
    );
  }

  // 添加技术指标
  // void addIndicator(UiIndicator indicator, int i) {
  //   state.dynamicIndicators.add(indicator);
  // }

  // 更新布局尺寸
  void updateLayoutSize(Size size) {
    double ratio = 1;
    if (state.indicators.length <= 4) {
      ratio = chartHeightMap[state.indicators.length]!;
    }
    final klineChartWidth = size.width - state.klineChartLeftMargin - state.klineChartRightMargin;
    double klineStep = _calcVisibleKlineStep(state.visibleKlineCount, klineChartWidth);
    double klineWidth = _calcVisibleKlineWidth(klineStep);
    state = state.copyWith(
      klineCtrlWidth: size.width,
      klineCtrlHeight: size.height,
      klineChartWidth: klineChartWidth,
      klineChartHeight: _getKlineChartHeight(size.height, state.klineType, ratio),
      indicatorChartHeight: _getIndicatorChartHeight(
        size.height,
        state.klineType,
        ratio,
        state.indicators.length,
      ),
      klineStep: klineStep,
      klineWidth: klineWidth,
    );
  }

  // 隐藏十字线
  void hideCrossLine() {
    state = state.copyWith(
      crossLineFollowCursorPos: Offset.zero,
      crossLineFollowKlineIndex: -1,
      crossLineMode: CrossLineMode.none,
    );
  }

  // 单击左键盘方向键
  void keyDownArrowLeft() {
    int crossLineFollowKlineIndex = state.crossLineFollowKlineIndex;
    UiKlineRange klineRng = state.klineRng;
    final klines = state.klines;
    if (crossLineFollowKlineIndex == -1) {
      // 如果十字线未显示，默认设置为最后一根K线
      state = state.copyWith(
        crossLineFollowKlineIndex: klines.length - 1,
        crossLineMode: CrossLineMode.followKline,
      );
    } else if ((crossLineFollowKlineIndex == klineRng.begin) && (klineRng.begin > 0)) {
      klineRng.begin -= 1;
      klineRng.end -= 1;
      crossLineFollowKlineIndex -= 1;
      final (minPrice, maxPrice) = _calcKlineRngMinMaxPrice(klineRng, klines, state.emaCurves);
      state = state.copyWith(
        klineRng: klineRng,
        crossLineFollowKlineIndex: crossLineFollowKlineIndex,
        crossLineMode: CrossLineMode.followKline,
        klineRngMinPrice: minPrice,
        klineRngMaxPrice: maxPrice,
      );
    } else {
      crossLineFollowKlineIndex -= 1; // 向左移动十字线
      state = state.copyWith(
        crossLineFollowKlineIndex: crossLineFollowKlineIndex,
        crossLineMode: CrossLineMode.followKline,
      );
    }
    updateEmaPrices();
    showKlineInfoCtrl(true);
  }

  void showKlineInfoCtrl(bool visible) {
    int crossLineFollowKlineIndex = state.crossLineFollowKlineIndex;
    if (crossLineFollowKlineIndex < 0) {
      return; // 十字线未设置时不显示K线信息
    }
    final klines = state.klines;
    final kline = visible ? klines[crossLineFollowKlineIndex] : klines[0];
    double yesterdayPriceClose = 0;
    if (crossLineFollowKlineIndex > 0) {
      yesterdayPriceClose = klines[crossLineFollowKlineIndex - 1].priceClose;
    } else {
      yesterdayPriceClose = klines[0].priceOpen;
    }
    ref.read(klineInfoCtrlProvider.notifier).update(kline, yesterdayPriceClose, visible);
  }

  // 单击由键盘方向键
  void keyDownArrowRight() {
    int crossLineFollowKlineIndex = state.crossLineFollowKlineIndex;
    final klineRng = state.klineRng;
    final klines = state.klines;
    if (crossLineFollowKlineIndex == -1) {
      // 如果十字线未设置，默认设置为最后一根K线
      state = state.copyWith(
        crossLineFollowKlineIndex: klines.length - 1,
        crossLineMode: CrossLineMode.followKline,
      );
    } else if ((crossLineFollowKlineIndex >= state.klineRng.end) &&
        (klineRng.end < klines.length - 1)) {
      // 如果十字线在可视范围的最后一根K线上，向右移动时需要扩展可视范围
      klineRng.begin += 1;
      klineRng.end += 1;
      crossLineFollowKlineIndex += 1;
      final (minPrice, maxPrice) = _calcKlineRngMinMaxPrice(klineRng, klines, state.emaCurves);
      state = state.copyWith(
        klineRng: klineRng,
        crossLineFollowKlineIndex: crossLineFollowKlineIndex,
        crossLineMode: CrossLineMode.followKline,
        klineRngMinPrice: minPrice,
        klineRngMaxPrice: maxPrice,
      );
    } else if (crossLineFollowKlineIndex >= klines.length - 1) {
      return; // 已经是最后一根K线了,界面不需要刷新
    } else {
      crossLineFollowKlineIndex += 1; // 向右移动十字线
      state = state.copyWith(
        crossLineFollowKlineIndex: crossLineFollowKlineIndex,
        crossLineMode: CrossLineMode.followKline,
      );
    }
    updateEmaPrices();
    showKlineInfoCtrl(true);
  }

  // 更新十字线模式和位置
  void updateCrossLine({CrossLineMode? mode, int? klineIndex, Offset? pos}) {
    if (pos != null) {
      if ((pos.dx > state.klineChartLeftMargin) &&
          pos.dx < (state.klineChartLeftMargin + state.klineChartWidth)) {
        if (state.crossLineMode != CrossLineMode.none) {
          final klineIndex = _calcCrossLineFollowKlineIndex(pos);
          state = state.copyWith(
            crossLineFollowCursorPos: pos,
            crossLineFollowKlineIndex: klineIndex,
            crossLineMode: CrossLineMode.followCursor,
          );
          final klineInfo = ref.read(klineInfoCtrlProvider);
          if (klineInfo.visible) {
            showKlineInfoCtrl(true);
          }
        }
      }
    }
    if (klineIndex != null) {
      state = state.copyWith(crossLineFollowKlineIndex: klineIndex);
    }
    if (mode != null) {
      state = state.copyWith(crossLineMode: mode);
    }
  }

  int _calcCrossLineFollowKlineIndex(Offset localPosition) {
    final index = (localPosition.dx / state.klineStep).floor();
    return index + state.klineRng.begin;
  }

  // 放大
  void zoomIn() {
    int crossLineFollowKlineIndex = state.crossLineFollowKlineIndex;
    UiKlineRange klineRng = state.klineRng;
    if (crossLineFollowKlineIndex == -1) {
      crossLineFollowKlineIndex = state.klines.length - 1; // 放大中心为最右边K线
    }
    // 可见K线数量少于5，不再放大
    if (klineRng.end <= klineRng.begin + 6) {
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
      klineRng.begin = klineRng.end - 6;
    }

    if (klineRng.begin < 0) {
      klineRng.begin = 0;
    }
    if (klineRng.end > state.klines.length - 1) {
      klineRng.end = state.klines.length - 1;
    }
    int visibleKlineCount = klineRng.end - klineRng.begin + 1;
    // 注意点，如果K线数量很少，且
    double klineStep = _calcVisibleKlineStep(
      visibleKlineCount <= 6 ? 9 : visibleKlineCount,
      state.klineChartWidth,
    );
    double klineWidth = _calcVisibleKlineWidth(klineStep);
    final (klineRngMinPrice, klineRngMaxPrice) = _calcKlineRngMinMaxPrice(
      klineRng,
      state.klines,
      state.emaCurves,
    );
    state = state.copyWith(
      klineRng: klineRng,
      visibleKlineCount: visibleKlineCount,
      crossLineFollowKlineIndex: crossLineFollowKlineIndex,
      crossLineMode: CrossLineMode.followKline,
      klineStep: klineStep,
      klineWidth: klineWidth,
      klineRngMinPrice: klineRngMinPrice,
      klineRngMaxPrice: klineRngMaxPrice,
    );
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

  // 缩小
  void zoomOut() {
    int crossLineFollowKlineIndex = state.crossLineFollowKlineIndex;
    UiKlineRange klineRng = state.klineRng;
    if (crossLineFollowKlineIndex == -1) {
      crossLineFollowKlineIndex = state.klines.length - 1; // 缩小中心为最右边K线
    }
    // 可见K线数量大于等于总K线数量，不再缩小
    if (state.visibleKlineCount == state.klines.length) {
      // CrossLine的坐标也要同步更正
      double klineStep = state.klineChartWidth / state.visibleKlineCount * 0.95;
      int klineWidth = (state.klineStep * 0.8).floor();
      klineWidth = _ensureKlineWidth(klineStep, klineWidth);
      klineRng.begin = 0;
      klineRng.end = state.klines.length - 1;
      final (klineRngMinPrice, klineRngMaxPrice) = _calcKlineRngMinMaxPrice(
        klineRng,
        state.klines,
        state.emaCurves,
      );

      state = state.copyWith(
        klineRng: klineRng,
        klineStep: klineStep,
        klineWidth: klineWidth.toDouble(),
        klineRngMinPrice: klineRngMinPrice,
        klineRngMaxPrice: klineRngMaxPrice,
      );
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
    if (klineRng.end > state.klines.length - 1) {
      klineRng.end = state.klines.length - 1;
    }
    int visibleKlineCount = klineRng.end - klineRng.begin + 1;
    double klineStep = _calcVisibleKlineStep(visibleKlineCount, state.klineChartWidth);
    double klineWidth = _calcVisibleKlineWidth(klineStep);
    final (klineRngMinPrice, klineRngMaxPrice) = _calcKlineRngMinMaxPrice(
      klineRng,
      state.klines,
      state.emaCurves,
    );
    state = state.copyWith(
      klineRng: klineRng,
      visibleKlineCount: visibleKlineCount,
      crossLineFollowKlineIndex: crossLineFollowKlineIndex,
      crossLineMode: CrossLineMode.followKline,
      klineStep: klineStep,
      klineWidth: klineWidth,
      klineRngMinPrice: klineRngMinPrice,
      klineRngMaxPrice: klineRngMaxPrice,
    );
  }

  // 初始化可见K线范围和数量
  UiKlineRange _initKlineRng(List<UiKline> klines) {
    UiKlineRange klineRng = UiKlineRange(begin: 0, end: 0); // Initialize with default values
    if (klines.length < 120) {
      klineRng.begin = 0;
      klineRng.end = klines.length - 1;
    } else {
      klineRng.begin = klines.length - 120;
      if (klineRng.begin < 0) {
        klineRng.begin = 0;
      }
      klineRng.end = klines.length - 1;
    }
    return klineRng;
  }

  // 获取可见K线范围内的 最高价/最低价
  (double min, double max) _calcKlineRngMinMaxPrice(
    UiKlineRange klineRng,
    List<UiKline> klines,
    List<ShareEmaCurve> emaCurves,
  ) {
    double min = double.infinity;
    double max = double.negativeInfinity;
    for (int i = klineRng.begin; i <= klineRng.end; i++) {
      if (klines[i].priceMin < min) {
        min = klines[i].priceMin;
      }
      if (klines[i].priceMax > max) {
        max = klines[i].priceMax;
      }
    }
    if (emaCurves.isNotEmpty) {
      for (final curve in emaCurves) {
        if (curve.visible) {
          for (int i = klineRng.begin; i <= klineRng.end; i++) {
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
    return (min, max);
  }

  // 初始化附图指标，有可能需要从文件中加载
  List<UiIndicator> _initIndicators(KlineType klineType) {
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
    if (klineType == KlineType.day ||
        klineType == KlineType.week ||
        klineType == KlineType.month ||
        klineType == KlineType.quarter ||
        klineType == KlineType.year) {
      return indicators[0];
    } else if (klineType == KlineType.minute) {
      return indicators[1];
    } else if (klineType == KlineType.fiveDay) {
      return indicators[2];
    }
    return [];
  }

  // 初始化K线EMA数据
  void _calcIndicators(List<UiIndicator> indicators, List<UiKline> klines) {
    for (final indicator in indicators) {
      final calculator = indicatorCalculators[indicator.type];
      if (calculator == null) {
        continue;
      }
      final result = calculator(klines, {});
      _assignIndicator(indicator.type, result);
    }
  }

  // 填充技术指标计算结果
  void _assignIndicator(UiIndicatorType type, Map<String, List<double>> value) {
    switch (type) {
      case UiIndicatorType.macd:
        {
          state = state.copyWith(macd: value);
          break;
        }
      case UiIndicatorType.kdj:
        {
          state = state.copyWith(kdj: value);
          break;
        }
      case UiIndicatorType.boll:
        {
          state = state.copyWith(boll: value);
          break;
        }
      default:
        debugPrint('未知指标类型: $type');
    }
  }

  double _calcVisibleKlineStep(int visibleKlineCount, double klineChartWidth) {
    double klineStep = klineChartWidth / visibleKlineCount;
    return klineStep;
  }

  double _calcVisibleKlineWidth(double klineStep) {
    int klineWidth = (klineStep * 0.8).floor();
    return _ensureKlineWidth(klineStep, klineWidth).toDouble();
  }

  double _getKlineChartHeight(double height, KlineType klineType, double ratio) {
    height = height - state.klineCtrlTitleBarHeight;
    if (!klineType.isMinuteType) {
      height = height - state.klineCtrlTitleBarHeight + KlineCtrlLayout.titleBarMargin;
    }
    return (height * ratio).floorToDouble();
  }

  double _getIndicatorChartHeight(
    double height,
    KlineType klineType,
    double ratio,
    int indicatorCount,
  ) {
    height = height - state.klineCtrlTitleBarHeight;
    if (!klineType.isMinuteType) {
      height = height - state.klineCtrlTitleBarHeight + KlineCtrlLayout.titleBarMargin;
    }
    double scaleIndicator = (1 - ratio) / indicatorCount;
    return indicatorCount == 0 ? 0 : height * scaleIndicator;
  }
}

class KlineInfoState {
  UiKline kline;
  bool visible;
  double yesterdayPriceClose;
  KlineInfoState({required this.kline, required this.visible, required this.yesterdayPriceClose});

  KlineInfoState copyWith({UiKline? kline, bool? visible, double? yesterdayPriceClose}) {
    return KlineInfoState(
      kline: kline ?? this.kline,
      visible: visible ?? this.visible,
      yesterdayPriceClose: yesterdayPriceClose ?? this.yesterdayPriceClose,
    );
  }
}

class KlineInfoCtrlNotifier extends StateNotifier<KlineInfoState> {
  KlineInfoCtrlNotifier({required KlineInfoState klineInfoState})
    : super(
        KlineInfoState(
          kline: klineInfoState.kline,
          visible: klineInfoState.visible,
          yesterdayPriceClose: klineInfoState.yesterdayPriceClose,
        ),
      );
  void update(UiKline kline, double yesterdayPriceClose, bool visible) {
    state = KlineInfoState(
      kline: kline,
      visible: visible,
      yesterdayPriceClose: yesterdayPriceClose,
    );
  }
}

final klineInfoCtrlProvider = StateNotifierProvider<KlineInfoCtrlNotifier, KlineInfoState>((ref) {
  final kline = UiKline(day: "", volume: BigInt.zero);
  return KlineInfoCtrlNotifier(
    klineInfoState: KlineInfoState(kline: kline, visible: false, yesterdayPriceClose: 0),
  );
});

class EmaCurveNotifier extends StateNotifier<Map<int, double>> {
  EmaCurveNotifier({required Map<int, double> emaPrices}) : super(emaPrices);
  void update(Map<int, double> emaPrices) {
    state = emaPrices;
  }
}

final emaCurveProvider = StateNotifierProvider<EmaCurveNotifier, Map<int, double>>((ref) {
  Map<int, double> emaPrices = {};
  return EmaCurveNotifier(emaPrices: emaPrices);
});
