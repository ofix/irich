import 'package:flutter/material.dart';
import 'package:irich/components/indicators/amount_indicator.dart';
import 'package:irich/components/indicators/minute_amount_indicator.dart';
import 'package:irich/components/indicators/minute_volume_indicator%20copy.dart';
import 'package:irich/components/indicators/turnoverrate_indicator.dart';
import 'package:irich/components/indicators/volume_indicator.dart';
import 'package:irich/components/kline_ctrl/kline_chart.dart';
import 'package:irich/types/stock.dart';

class KlineState {
  String shareCode; // 股票代码
  KlineType type = KlineType.day; // 当前绘制的K线类型
  late List<UiKline> klines; // 前复权日K线数据
  late List<MinuteKline> minuteKlines; // 分时K线数据
  late List<MinuteKline> fiveDayMinuteKlines; // 五日分时K线数据
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
    required this.fiveDayMinuteKlines,
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
      fiveDayMinuteKlines: fiveDayMinuteKlines ?? this.fiveDayMinuteKlines,
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
  final KlineState klineState;
  const KlineCtrl({super.key, required this.klineState});
  @override
  State<KlineCtrl> createState() => _KlineCtrlState();
}

class _KlineCtrlState extends State<KlineCtrl> {
  int activeKlineType = 1;
  static const Map<String, KlineType> klineTypeMap = {
    '分时': KlineType.minute,
    '五日': KlineType.fiveDay,
    '日K': KlineType.day,
    '周K': KlineType.week,
    '月K': KlineType.month,
    '季K': KlineType.quarter,
    '年K': KlineType.year,
  };
  static const Map<String, int> emaCurveMap = {
    'EMA5': 5,
    'EMA10': 10,
    'EMA20': 20,
    'EMA30': 30,
    'EMA60': 60,
    'EMA255': 255,
    'EMA905': 905,
  };

  static const Map<String, UiIndicatorType> indicatorMap = {
    "成交量": UiIndicatorType.volume,
    "成交额": UiIndicatorType.amount,
    "换手率": UiIndicatorType.turnoverRate,
    "分时成交量": UiIndicatorType.minuteVolume,
    "分时成交额": UiIndicatorType.minuteAmount,
    "五日分时成交量": UiIndicatorType.fiveDayMinuteVolume,
    "五日分时成交额": UiIndicatorType.fiveDayMinuteAmount,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children:
          // K 线类型切换
          _buildTypeButtons(context, klineTypeMap, activeKlineType),
        ),
        const Spacer(),
        Column(
          children:
          // EMA控制
          _buildEmaButtons(context, emaCurveMap),
        ),
        const Spacer(),
        // K线主图
        KlineChart(shareCode: widget.klineState.shareCode),
        const Spacer(),
        // 技术指标图
        Row(children: _buildIndicators(context, widget.klineState, indicatorMap)),
      ],
    );
  }

  List<Widget> _buildTypeButtons(
    BuildContext context,
    Map<String, KlineType> texts,
    activeKlineType,
  ) {
    List<Widget> widgets = [];
    int i = 0;
    for (final entry in texts.entries) {
      bool isActive = activeKlineType == i;
      TextButton button = TextButton(
        style: TextButton.styleFrom(foregroundColor: isActive ? Colors.blue : Colors.white),
        onPressed: () => activeKlineType = i,
        child: Text(entry.key),
      );
      i++;
      widgets.add(button);
    }

    return widgets;
  }

  List<Widget> _buildEmaButtons(BuildContext context, emaCurveMap) {
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

  Color _getEmaColor(int period) {
    return switch (period) {
      5 => Colors.green,
      10 => Colors.white,
      20 => const Color(0xFFEF486F),
      30 => const Color(0xFFFF9F1A),
      60 => const Color(0xFFC9F3F0),
      _ => Colors.purple,
    };
  }

  // 技术指标附图
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
            minuteKlines: klineState.fiveDayMinuteKlines,
            klineType: klineState.type,
            crossLineIndex: klineState.crossLineIndex,
          ),
        );
      } else if (indicator.value == UiIndicatorType.fiveDayMinuteVolume) {
        widgets.add(
          MinuteVolumeIndicator(
            minuteKlines: klineState.fiveDayMinuteKlines,
            klineType: klineState.type,
            crossLineIndex: klineState.crossLineIndex,
          ),
        );
      }
    }
    return widgets;
  }
}
