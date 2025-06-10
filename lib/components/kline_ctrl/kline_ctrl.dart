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
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:irich/store/state_kline_ctrl.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/theme/stock_colors.dart';

class KlineCtrl extends ConsumerStatefulWidget {
  const KlineCtrl({super.key});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _KlineCtrlState();
}

class _KlineCtrlState extends ConsumerState<KlineCtrl> {
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
  late KlineCtrlState klineCtrlState;
  Share? share;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    klineCtrlState = KlineCtrlState(klineType: KlineType.day);
    _focusNode = FocusNode();
    _focusNode.requestFocus();
  }

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

  // 加载K线数据

  @override
  Widget build(BuildContext context) {
    // final shareCode = ref.watch(currentShareCodeProvider);
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
        // Size size = Size(constraints.maxWidth, constraints.maxHeight);
        // updateSize(size); // 计算K线图宽高,当前显示的K线图范围
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
                    _buildFavoriteButton(klineCtrlState.share!.isFavorite, stockColors),
                  ],
                ),
                // K线主图
                KlineChart(klineCtrlState: klineCtrlState, stockColors: stockColors, share: share!),
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

  /// 股票名称组件
  Widget _buildKlineName() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8), // 左右各16像素
      child: Text(
        share!.name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: const Color.fromARGB(255, 219, 137, 36),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// K线类别组件
  Widget _buildKlineTypeTabs() {
    return RichRadioButtonGroup(
      options: ["日K", "周K", "月K", "季K", "年K", "分时", "五日"],
      onChanged: (value) {
        _onKlineTypeChanged(value);
      },
      height: KlineCtrlLayout.titleBarHeight,
    );
  }

  // 自选按钮组件
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

  // 技术指标副图组件
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

  /// 添加股票到自选池
  void _onToggleFavoriteButton() {
    share!.isFavorite = !share!.isFavorite;
    StoreQuote.addFavoriteShare(share!.code);
  }

  /// 切换股票类别
  void _onKlineTypeChanged(String value) async {
    final klineType = klineTypeMap[value]!;
    ref.read(klineCtrlProvider.notifier).changeKlineType(klineType);
  }

  // 键盘上/下/左/右/Escape/Home/End功能键 事件响应
  KeyEventResult _onKeyEvent(FocusNode focosNode, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        ref.read(klineCtrlProvider.notifier).keyDownArrowLeft();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        ref.read(klineCtrlProvider.notifier).keyDownArrowRight();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        ref.read(klineCtrlProvider.notifier).zoomIn();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        ref.read(klineCtrlProvider.notifier).zoomOut();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        ref.read(klineCtrlProvider.notifier).hideCrossLine();
      } else if (event.logicalKey == LogicalKeyboardKey.home) {
        ref
            .read(klineCtrlProvider.notifier)
            .updateCrossLine(CrossLineMode.followKline, ref.read(klineCtrlProvider).klineRng.begin);
      } else if (event.logicalKey == LogicalKeyboardKey.end) {
        ref
            .read(klineCtrlProvider.notifier)
            .updateCrossLine(CrossLineMode.followKline, ref.read(klineCtrlProvider).klineRng.end);
      }
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
      // 支持重复按键事件
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        ref.read(klineCtrlProvider.notifier).keyDownArrowLeft();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        ref.read(klineCtrlProvider.notifier).keyDownArrowRight();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.home ||
          event.logicalKey == LogicalKeyboardKey.end) {
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored; // 继续键盘事件传播
  }

  /// 用户单击鼠标的时候也需要记住单击位置所在的K线下标，以此为中心点进行缩放
  void _onTapDown(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    // 计算点击的K线索引
    ref.read(klineCtrlProvider.notifier).updateCrossLinePos(localPosition);
  }

  /// 鼠标移动事件
  void _onPointerHover(PointerEvent event) {
    _onMouseMove(event.localPosition);
  }

  // 鼠标移动的时候需要动态绘制十字光标
  void _onMouseMove(Offset localPosition) {
    ref.read(klineCtrlProvider.notifier).updateCrossLinePos(localPosition);
  }

  // 鼠标滚轮事件处理,可以用来切换股票
  void _onMouseScroll(PointerEvent event) {
    if (event is PointerScrollEvent) {
      if (event.scrollDelta.dy > 0) {
      } else {}
    }
  }

  void logError(String s, {required Object error, required StackTrace stackTrace}) {}
}
