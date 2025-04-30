import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:irich/components/kline_ctrl/kline_chart_painter.dart';
import 'package:irich/formula/formula_ema.dart';
import 'package:irich/store/store_klines.dart';
import 'package:irich/types/stock.dart';
import 'package:irich/utils/rich_result.dart';

class KlineChart extends StatefulWidget {
  final String shareCode;
  const KlineChart({super.key, required this.shareCode});

  @override
  State<KlineChart> createState() => _KlineChartState();
}

class _KlineChartState extends State<KlineChart> {
  late String shareCode; // 股票代码
  late KlineType type; // 当前绘制的K线类型
  late List<UiKline> klines; // 前复权日K线数据
  late List<MinuteKline> minuteKlines; // 分时K线数据
  late List<MinuteKline> fiveDayMinuteKlines; // 五日分时K线数据
  late UiKlineRange klineRng; // 可视K线范围
  late List<ShareEmaCurve> emaCurves; // EMA曲线数据
  late List<List<UiIndicator>> indicators; // 0:日/周/月/季/年K线技术指标列表,1:分时图技术指标列表,2:五日分时图技术指标列表
  late int visibleIndicatorIndex; // 需要显示的技术指标索引
  late String stockCode; // 当前股票代码
  late int crossLineIndex; // 十字线位置
  late double klineWidth; // K线宽度
  late double klineInnerWidth; // K线内部宽度
  late int visibleKlineCount; // 可视区域K线数量

  final FocusNode _focusNode = FocusNode();
  @override
  void initState() async {
    super.initState();
    await loadKlines(stockCode, type);
    // 初始化K线数据

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
        child: GestureDetector(
          onTapDown: _handleTapDown,
          child: Transform.scale(
            scale: 1.0,
            child: Container(
              width: 800,
              height: 600,
              color: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.only(left: 48, right: 48, top: 16, bottom: 16), // 背景色
              child: CustomPaint(
                size: Size.infinite,
                painter: KlinePainter(
                  klineType: type,
                  klines: klines,
                  minuteKlines: minuteKlines,
                  fiveDayMinuteKlines: fiveDayMinuteKlines,
                  klineRng: klineRng,
                  emaCurves: emaCurves,
                  crossLineIndex: crossLineIndex,
                  klineWidth: klineWidth,
                  klineInnerWidth: klineInnerWidth,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  void _handleTapDown(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    // 计算点击的K线索引
    final index = (localPosition.dx / klineWidth).floor();
    crossLineIndex = index;
    setState(() {});
  }

  void _handleScroll(PointerEvent event) {
    if (event is PointerScrollEvent) {
      setState(() {});
    }
  }

  void logError(String s, {required Object error, required StackTrace stackTrace}) {}

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

  void initIndicators() {
    List<List<UiIndicator>> indicators = [
      [
        UiIndicator(type: UiIndicatorType.amount, visible: true, height: 100),
        UiIndicator(type: UiIndicatorType.volume, visible: true, height: 100),
        UiIndicator(type: UiIndicatorType.turnoverRate, visible: true, height: 100),
      ],
      [
        UiIndicator(type: UiIndicatorType.minuteAmount, visible: false, height: 100),
        UiIndicator(type: UiIndicatorType.minuteVolume, visible: false, height: 100),
      ],
      [
        UiIndicator(type: UiIndicatorType.fiveDayMinuteAmount, visible: false, height: 100),
        UiIndicator(type: UiIndicatorType.fiveDayMinuteVolume, visible: false, height: 100),
      ],
    ];

    indicators = indicators;
    visibleIndicatorIndex = 0;
  }

  // 添加技术指标
  void addIndicator(UiIndicator indicator, int i) {
    indicators[i].add(indicator);
  }

  List<dynamic> _getKlinesListForType(KlineType type) {
    return type.isMinuteType ? minuteKlines : klines;
  }

  // 切换K线类型
  void setType(KlineType type) {
    // 需要切换技术指标
    if (type == KlineType.day ||
        type == KlineType.week ||
        type == KlineType.month ||
        type == KlineType.quarter ||
        type == KlineType.year) {
      visibleIndicatorIndex = 0;
    } else if (type == KlineType.minute) {
      visibleIndicatorIndex = 1;
    } else {
      visibleIndicatorIndex = 2;
    }
  }

  // 添加EMA曲线
  bool addEmaCurve(int period, Color color) {
    if (emaCurves.length >= 8) {
      // 一个界面最多显示8条EMA平滑移动价格曲线
      return false;
    }
    ShareEmaCurve curve = ShareEmaCurve(color: color, period: period, visible: true, emaPrice: []);
    curve.emaPrice = FormulaEma.calculateEma(klines, period);
    // state = copyWith(emaCurves: [...emaCurves, curve]);
    return true;
  }

  // 移除所有匹配指定周期的曲线
  bool removeEmaCurve(int period) {
    final originalLength = emaCurves.length;
    emaCurves.removeWhere((curve) => curve.period == period);
    return emaCurves.length != originalLength;
  }

  // 处理放大逻辑
  void zoomIn(Size size) {
    if (crossLineIndex == -1) {
      crossLineIndex = klines.length - 1; // 放大中心为最右边K线
    }
    // 可见K线数量少于8，不再放大
    if (klineRng.end <= klineRng.begin + 8) {
      return;
    }

    // 计算放大中心两边的K线数量
    int leftKlineCount = crossLineIndex - klineRng.begin;
    int rightKlineCount = klineRng.end - crossLineIndex;
    // 取中心点左右两侧K线较多的一边进行延展，保住中心的地位
    int count = leftKlineCount > rightKlineCount ? leftKlineCount : rightKlineCount;
    klineRng.begin = crossLineIndex - count ~/ 2;
    klineRng.end = crossLineIndex + count ~/ 2;

    if (klineRng.begin > klineRng.end) {
      klineRng.begin = klineRng.end - 8;
    }
    // 边界处理
    if (klineRng.begin < 0) {
      klineRng.begin = 0;
    }
    if (klineRng.end > klines.length - 1) {
      klineRng.end = klines.length - 1;
    }

    visibleKlineCount = klineRng.end - klineRng.begin + 1;
    calcVisibleKlineWidth(size);
  }

  // 计算可视范围K线自适应宽度
  void calcVisibleKlineWidth(Size size) {
    if (klines.length < 20) {
      klineWidth = 10;
      klineInnerWidth = 7;
    } else {
      klineWidth = size.width / visibleKlineCount;
      klineInnerWidth = klineWidth * 0.8;
      if (klineWidth > 1 && klineInnerWidth % 2 == 0) {
        klineInnerWidth = klineInnerWidth;
        klineInnerWidth -= 1;
        if (klineInnerWidth < 1) {
          klineInnerWidth = 1;
        }
      }
    }
    // 根据K线宽度计算起始坐标和放大坐标
    if (crossLineIndex == -1) {
      klineRng.begin = klines.length - visibleKlineCount;
      klineRng.end = klines.length - 1;
      if (klineRng.begin < 0) {
        klineRng.begin = 0;
      }
    }
  }

  // 实现缩小逻辑
  void zoomOut() {}

  // 处理十字线移动
  void moveCrossLine(int index) {
    // state = copyWith(crossLineIndex: index);
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

  void _handleDragUpdate(DragUpdateDetails details) {}
}
