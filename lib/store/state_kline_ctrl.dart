// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/state_kline_ctrl.dart
// Purpose:     kline ctrl provider
// Author:      songhuabiao
// Created:     2025-06-10 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/formula/formula_boll.dart';
import 'package:irich/formula/formula_ema.dart';
import 'package:irich/formula/formula_kdj.dart';
import 'package:irich/formula/formula_macd.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/state_quote.dart';
import 'package:irich/store/store_klines.dart';
import 'package:irich/utils/rich_result.dart';

final klineCtrlProvider = StateNotifierProvider<KlineCtrlNotifier, KlineCtrlState>((ref) {
  final notifier = KlineCtrlNotifier();
  // 监听股票代码变化，自动触发更新
  ref.listen<String>(currentShareCodeProvider, (_, newCode) {
    if (newCode.isNotEmpty) notifier.changeShareCode(newCode);
  });
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

  StoreKlines storeKlines = StoreKlines();

  KlineCtrlNotifier() : super(KlineCtrlState(klineType: KlineType.day));

  // 切换股票代码的时候需要重新初始化
  void changeShareCode(String shareCode) async {
    // 更新股票
    // Share? share = StoreQuote.query(shareCode);
    RichResult result = await _queryKlines(storeKlines, shareCode, state.klineType);
    if (!result.ok()) {
      return;
    }
    final klineRng = _initKlineRng(state.klines);
    final visibleKlineCount = klineRng.end - klineRng.begin + 1;

    double klineStep = _calcVisibleKlineStep(visibleKlineCount);
    double klineWidth = _calcVisibleKlineWidth(klineStep);

    // 先初始化EMA曲线和EMA价格
    if (state.emaCurves.isEmpty) {
      for (final setting in state.emaCurveSettings) {
        addEmaCurve(setting.period, setting.color);
      }
    } else {
      updateAllEmaCurves();
    }
    // 初始化技术指标附图
    List<UiIndicator> indicators = _initIndicators(state.klineType);
    // 填充技术指标数据
    _calcIndicators(indicators, state.klines);
    // 初始化可见范围最高价/最低价
    final (klineRngMinPrice, klineRngMaxPrice) = _calcKlineRngMinMaxPrice(
      klineRng,
      state.klines,
      state.emaCurves,
    );

    state = state.copyWith(
      klineRng: klineRng,
      visibleKlineCount: visibleKlineCount,
      klineStep: klineStep,
      klineWidth: klineWidth,
      indicators: indicators,
      dynamicIndicators: indicators,
      klineRngMinPrice: klineRngMinPrice,
      klineRngMaxPrice: klineRngMaxPrice,
    );
  }

  Future<RichResult> _queryKlines(StoreKlines store, String stockCode, KlineType type) async {
    // 统一处理所有返回 (RichResult, List<T>) 的K线类型
    Future<RichResult> handleQuery<T>(
      Future<(RichResult, List<T>)> Function(String) queryFn,
      void Function(List<T>) assignFn,
    ) async {
      final (result, data) = await queryFn(stockCode);
      if (result.ok()) assignFn(data);
      return result;
    }

    return switch (type) {
      KlineType.day => handleQuery<UiKline>(store.queryDayKlines, (v) => state.klines = v),
      KlineType.week => handleQuery<UiKline>(store.queryWeekKlines, (v) => state.klines = v),
      KlineType.month => handleQuery<UiKline>(store.queryMonthKlines, (v) => state.klines = v),
      KlineType.quarter => handleQuery<UiKline>(store.queryQuarterKlines, (v) => state.klines = v),
      KlineType.year => handleQuery<UiKline>(store.queryYearKlines, (v) => state.klines = v),
      KlineType.minute => handleQuery<MinuteKline>(
        store.queryMinuteKlines,
        (v) => state.minuteKlines = v,
      ),
      KlineType.fiveDay => handleQuery<MinuteKline>(
        store.queryFiveDayMinuteKlines,
        (v) => state.fiveDayMinuteKlines = v,
      ),
    };
  }

  void changeKlineType(KlineType type) {}

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
  bool toggleEmaCurve(int period) {
    final curves = state.emaCurves;
    bool bSuccess = false;
    for (final curve in curves) {
      if (curve.period == period) {
        curve.visible = !curve.visible;
        bSuccess = true;
      }
    }
    if (bSuccess) {
      final (klineRngMinPrice, klineRngMaxPrice) = _calcKlineRngMinMaxPrice(
        state.klineRng,
        state.klines,
        state.emaCurves,
      );
      state = state.copyWith(
        emaCurves: curves,
        klineRngMinPrice: klineRngMinPrice,
        klineRngMaxPrice: klineRngMaxPrice,
      );
    }
    return bSuccess;
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
    double klineStep = _calcVisibleKlineStep(state.visibleKlineCount);
    double klineWidth = _calcVisibleKlineWidth(klineStep);
    state = state.copyWith(
      klineCtrlWidth: size.width,
      klineCtrlHeight: size.height,
      klineChartWidth: size.width - state.klineChartLeftMargin - state.klineChartRightMargin,
      klineChartHeight: _getKlineChartHeight(size.height, state.klineType, ratio),
      indicatorChartHeight: _getIndicatorChartHeight(size.height, state.klineType, ratio),
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
  }

  // 更新十字线模式和位置
  void updateCrossLine(CrossLineMode mode, int klineIndex) {
    state = state.copyWith(crossLineFollowKlineIndex: klineIndex, crossLineMode: mode);
  }

  // 更新十字线位置
  void updateCrossLinePos(Offset pos) {
    if ((pos.dx > state.klineChartLeftMargin) &&
        pos.dx < (state.klineChartLeftMargin + state.klineChartWidth)) {
      if (state.crossLineMode != CrossLineMode.none) {
        final klineIndex = _calcCrossLineFollowKlineIndex(pos);

        state = state.copyWith(
          crossLineFollowCursorPos: pos,
          crossLineFollowKlineIndex: klineIndex,
          crossLineMode: CrossLineMode.followCursor,
        );
      }
    }
  }

  int _calcCrossLineFollowKlineIndex(Offset localPosition) {
    final index = (localPosition.dx / state.klineStep).floor();
    return index + state.klineRng.begin;
  }

  // 更新十字线模式
  void updateCrossLineMode(CrossLineMode mode) {
    state = state.copyWith(crossLineMode: mode);
  }

  // 放大
  void zoomIn() {
    int crossLineFollowKlineIndex = state.crossLineFollowKlineIndex;
    UiKlineRange klineRng = state.klineRng;
    if (crossLineFollowKlineIndex == -1) {
      crossLineFollowKlineIndex = state.klines.length - 1; // 放大中心为最右边K线
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
    if (klineRng.end > state.klines.length - 1) {
      klineRng.end = state.klines.length - 1;
    }
    double klineStep = _calcVisibleKlineStep(state.visibleKlineCount);
    double klineWidth = _calcVisibleKlineWidth(klineStep);
    final (klineRngMinPrice, klineRngMaxPrice) = _calcKlineRngMinMaxPrice(
      klineRng,
      state.klines,
      state.emaCurves,
    );
    state = state.copyWith(
      klineRng: klineRng,
      visibleKlineCount: klineRng.end - klineRng.begin + 1,
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
      debugPrint("无法继续缩放了！");
      double klineStep = state.klineChartWidth / state.visibleKlineCount * 0.85;
      int klineWidth = (state.klineStep * 0.8).floor();
      klineWidth = _ensureKlineWidth(klineStep, klineWidth);
      final (klineRngMinPrice, klineRngMaxPrice) = _calcKlineRngMinMaxPrice(
        klineRng,
        state.klines,
        state.emaCurves,
      );
      state = state.copyWith(
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
    double klineStep = _calcVisibleKlineStep(state.visibleKlineCount);
    double klineWidth = _calcVisibleKlineWidth(klineStep);
    final (klineRngMinPrice, klineRngMaxPrice) = _calcKlineRngMinMaxPrice(
      klineRng,
      state.klines,
      state.emaCurves,
    );
    state = state.copyWith(
      klineRng: klineRng,
      visibleKlineCount: klineRng.end - klineRng.begin + 1,
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
          state.macd = value;
          break;
        }
      case UiIndicatorType.kdj:
        {
          state.kdj = value;
          break;
        }
      case UiIndicatorType.boll:
        {
          state.boll = value;
          break;
        }
      default:
        debugPrint('未知指标类型: $type');
    }
  }

  double _calcVisibleKlineStep(int visibleKlineCount) {
    Size size = Size(state.klineChartWidth, state.klineChartHeight);
    if (state.klines.isEmpty) {
      return 1;
    }
    double klineStep = size.width / visibleKlineCount;
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

  double _getIndicatorChartHeight(double height, KlineType klineType, double ratio) {
    height = height - state.klineCtrlTitleBarHeight;
    if (!klineType.isMinuteType) {
      height = height - state.klineCtrlTitleBarHeight + KlineCtrlLayout.titleBarMargin;
    }
    double scaleIndicator = (1 - ratio) / state.indicators.length;
    return state.indicators.isEmpty ? 0 : height * scaleIndicator;
  }
}
