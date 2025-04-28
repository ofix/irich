import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/formula/formula_ema.dart';
import 'package:irich/store/store_klines.dart';
import 'package:irich/types/stock.dart';
import 'package:irich/utils/rich_result.dart';

class KlineState {
  KlineType type; // 当前绘制的K线类型
  List<UiKline> klines; // 前复权日K线数据
  List<MinuteKline> minuteKlines; // 分时K线数据
  List<MinuteKline> fiveDayMinuteKlines; // 五日分时K线数据
  UiKlineRange klineRng; // 可视K线范围
  List<ShareEmaCurve> emaCurves; // EMA曲线数据
  String stockCode; // 当前股票代码
  int crossLineIndex; // 十字线位置
  double klineWidth; // K线宽度
  double klineInnerWidth; // K线内部宽度
  int visibleKlineCount; // 可视区域K线数量

  double width; // 画布宽度
  double minKlinePrice; // 可视区域K线最低价
  double maxKlinePrice; // 可视区域K线最高价
  double minRectPrice; // 如果有EMA均线，可视区域最低价会变化
  double maxRectPrice; // 如果有EMA均线，可视区域最高价会变化
  int minRectPriceIndex; // 可见K线中最低价K线位置
  int maxRectPriceIndex; // 可见K险种最高价K线位置

  KlineState({
    this.type = KlineType.day,
    this.klines = const [],
    this.minuteKlines = const [],
    this.fiveDayMinuteKlines = const [],
    this.emaCurves = const [],
    UiKlineRange? klineRng,
    this.stockCode = '',
    this.crossLineIndex = -1,
    this.klineWidth = 7,
    this.klineInnerWidth = 5.6,
    this.width = 960,
    this.visibleKlineCount = 120,
    this.minKlinePrice = 0,
    this.maxKlinePrice = 0,
    this.minRectPrice = 0,
    this.maxRectPrice = 0,
    this.minRectPriceIndex = 0,
    this.maxRectPriceIndex = 0,
  }) : klineRng = klineRng ?? UiKlineRange(begin: 0, end: 0);

  KlineState copyWith({
    KlineType? type,
    List<UiKline>? klines,
    List<MinuteKline>? minuteKlines,
    List<MinuteKline>? fiveDayMinuteKlines,
    List<ShareEmaCurve>? emaCurves,
    String? stockCode,
    int? crossLineIndex,
    double? klineWidth,
    double? klineInnerWidth,
    double? width,
    int? visibleKlineCount,
    double? minKlinePrice,
    double? maxKlinePrice,
    double? minRectPrice,
    double? maxRectPrice,
    int? minRectPriceIndex,
    int? maxRectPriceIndex,
  }) {
    return KlineState(
      type: type ?? this.type,
      klines: klines ?? this.klines,
      minuteKlines: minuteKlines ?? this.minuteKlines,
      fiveDayMinuteKlines: fiveDayMinuteKlines ?? this.fiveDayMinuteKlines,
      emaCurves: emaCurves ?? this.emaCurves,
      stockCode: stockCode ?? this.stockCode,
      crossLineIndex: crossLineIndex ?? this.crossLineIndex,
      klineWidth: klineWidth ?? this.klineWidth,
      width: width ?? this.width,
      visibleKlineCount: visibleKlineCount ?? this.visibleKlineCount,
      minKlinePrice: minKlinePrice ?? this.minKlinePrice,
      maxKlinePrice: maxKlinePrice ?? this.maxKlinePrice,
      minRectPrice: minRectPrice ?? this.minRectPrice,
      maxRectPrice: maxRectPrice ?? this.maxRectPrice,
      minRectPriceIndex: minRectPriceIndex ?? this.minRectPriceIndex,
      maxRectPriceIndex: maxRectPriceIndex ?? this.maxRectPriceIndex,
    );
  }
}

// 状态管理
final klineProvider = StateNotifierProvider<KlineNotifier, KlineState>((ref) {
  return KlineNotifier();
});

class KlineNotifier extends StateNotifier<KlineState> {
  KlineNotifier() : super(KlineState());
  // 加载K线数据
  // 加载K线数据
  Future<bool> loadKlines(String stockCode, KlineType type) async {
    try {
      final store = StoreKlines();
      final result = await _queryKlines(store, stockCode, type);
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
    return type.isMinuteType ? state.minuteKlines : state.klines;
  }

  // 切换K线类型
  void setType(KlineType type) {
    state = state.copyWith(type: type);
  }

  // 添加EMA曲线
  bool addEmaCurve(int period, Color color) {
    if (state.emaCurves.length >= 8) {
      // 一个界面最多显示8条EMA平滑移动价格曲线
      return false;
    }
    ShareEmaCurve curve = ShareEmaCurve(color: color, period: period, visible: true, emaPrice: []);
    curve.emaPrice = FormulaEma.calculateEma(state.klines, period);
    state = state.copyWith(emaCurves: [...state.emaCurves, curve]);
    return true;
  }

  // 移除所有匹配指定周期的曲线
  bool removeEmaCurve(int period) {
    final originalLength = state.emaCurves.length;
    state.emaCurves.removeWhere((curve) => curve.period == period);
    return state.emaCurves.length != originalLength;
  }

  // 处理放大逻辑
  void zoomIn() {
    if (state.crossLineIndex == -1) {
      state.crossLineIndex = state.klines.length - 1; // 放大中心为最右边K线
    }
    // 可见K线数量少于8，不再放大
    if (state.klineRng.end <= state.klineRng.begin + 8) {
      return;
    }

    // 计算放大中心两边的K线数量
    int leftKlineCount = state.crossLineIndex - state.klineRng.begin;
    int rightKlineCount = state.klineRng.end - state.crossLineIndex;
    // 取中心点左右两侧K线较多的一边进行延展，保住中心的地位
    int size = leftKlineCount > rightKlineCount ? leftKlineCount : rightKlineCount;
    state.klineRng.begin = state.crossLineIndex - size ~/ 2;
    state.klineRng.end = state.crossLineIndex + size ~/ 2;

    if (state.klineRng.begin > state.klineRng.end) {
      state.klineRng.begin = state.klineRng.end - 8;
    }
    // 边界处理
    if (state.klineRng.begin < 0) {
      state.klineRng.begin = 0;
    }
    if (state.klineRng.end > state.klines.length - 1) {
      state.klineRng.end = state.klines.length - 1;
    }

    state.visibleKlineCount = state.klineRng.end - state.klineRng.begin + 1;
    calcVisibleKlineWidth();
  }

  // 计算可视范围K线自适应宽度
  void calcVisibleKlineWidth() {
    if (state.klines.length < 20) {
      state.klineWidth = 10;
      state.klineInnerWidth = 7;
    } else {
      state.klineWidth = state.width / state.visibleKlineCount;
      state.klineInnerWidth = state.klineWidth * 0.8;
      if (state.klineWidth > 1 && state.klineInnerWidth % 2 == 0) {
        state.klineInnerWidth = state.klineInnerWidth;
        state.klineInnerWidth -= 1;
        if (state.klineInnerWidth < 1) {
          state.klineInnerWidth = 1;
        }
      }
    }
    // 根据K线宽度计算起始坐标和放大坐标
    if (state.crossLineIndex == -1) {
      state.klineRng.begin = state.klines.length - state.visibleKlineCount;
      state.klineRng.end = state.klines.length - 1;
      if (state.klineRng.begin < 0) {
        state.klineRng.begin = 0;
      }
    }
  }

  // 实现缩小逻辑
  void zoomOut() {}

  // 处理十字线移动
  void moveCrossLine(int index) {
    state = state.copyWith(crossLineIndex: index);
  }

  double getRectMinPrice(List<UiKline> klines, int begin, int end) {
    double min = double.maxFinite;
    // 1. 先找出K线本身的最低价格
    for (int i = begin; i <= end; i++) {
      if (klines[i].priceMin < min) {
        min = klines[i].priceMin;
        state.minRectPriceIndex = i - begin; // 更新最低价索引
      }
    }
    state.minKlinePrice = min; // 保存最低价格
    // 2. 如果有EMA曲线，检查EMA值是否更低
    if (hasEmaCurve()) {
      for (final curve in state.emaCurves) {
        if (curve.visible) {
          for (int i = begin; i <= end; i++) {
            if (curve.emaPrice[i] < min) {
              min = curve.emaPrice[i];
            }
          }
        }
      }
    }

    state.minRectPrice = min; // 更新可视区域最低价
    return min;
  }

  double getRectMaxPrice(List<UiKline> klines, int begin, int end) {
    double max = -double.maxFinite;
    // 1. 先找出K线本身的最高价格
    for (int i = begin; i <= end; i++) {
      if (klines[i].priceMax > max) {
        max = klines[i].priceMax;
        state.maxRectPriceIndex = i - begin; // 更新最高价索引
      }
    }
    state.maxKlinePrice = max; // 保存最高价格
    // 2. 如果有EMA曲线，检查EMA值是否更高
    if (hasEmaCurve()) {
      for (final curve in state.emaCurves) {
        if (curve.visible) {
          for (int i = begin; i <= end; i++) {
            if (curve.emaPrice[i] > max) {
              max = curve.emaPrice[i];
            }
          }
        }
      }
    }
    state.maxRectPrice = max; // 更新可视区域最高价
    return max;
  }

  bool hasEmaCurve() {
    return state.emaCurves.isNotEmpty;
  }

  void logError(String s, {required Object error, required StackTrace stackTrace}) {}
}
