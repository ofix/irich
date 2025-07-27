// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/kline_ctrl/mini_kline_ctrl.dart
// Purpose:     kline chart painter
// Author:      songhuabiao
// Created:     2025-07-25 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/kline_ctrl/cross_line_chart.dart';
import 'package:irich/components/kline_ctrl/kline_chart.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/components/kline_ctrl/kline_info_panel.dart';
import 'package:irich/store/provider_kline_ctrl.dart';
import 'package:irich/store/provider_kline_grid.dart';
import 'package:irich/theme/stock_colors.dart';

class MiniKlineCtrl extends ConsumerStatefulWidget {
  final String shareCode; // 从父组件传入的股票代码
  const MiniKlineCtrl({super.key, required this.shareCode});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MiniKlineCtrlState();
}

class _MiniKlineCtrlState extends ConsumerState<MiniKlineCtrl> {
  late final FocusNode _focusNode;
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.requestFocus();
  }

  // 加载K线数据
  @override
  Widget build(BuildContext context) {
    final stockColors = Theme.of(context).extension<StockColors>()!;
    ref.watch(
      gridKlineCtrlProviders(widget.shareCode).select(
        (s) => (
          s.klineCtrlWidth,
          s.klineCtrlHeight,
          s.klineStep,
          s.klineRng.begin,
          s.klineRng.end,
          s.klineType,
          s.minuteWndMode,
          s.dataLoaded,
        ),
      ),
    );
    final miniKlineCtrlState = ref.read(gridKlineCtrlProviders(widget.shareCode));
    return Focus(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: MouseRegion(
        onHover: _onPointerHover, // 解决Listerner的onPointerHover方法无法触发鼠标移动的bug
        child: Listener(
          onPointerSignal: _onMouseScroll,
          child: GestureDetector(
            onTapDown: _onTapDown,
            child: buildMiniKlineCtrl(stockColors, miniKlineCtrlState),
          ),
        ),
      ),
    );
  }

  Widget buildMiniKlineCtrl(StockColors stockColors, KlineCtrlState state) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // final parentWidth = constraints.maxWidth; // 父容器可用宽度
        Size size = Size(constraints.maxWidth, constraints.maxHeight);
        final notifier = ref.read(klineCtrlProvider.notifier);
        if (size.width != state.klineCtrlWidth || size.height != state.klineCtrlHeight) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifier.updateLayoutSize(size);
          });
        }
        // 第一次初始化的时候只显示背景
        if (state.klineCtrlWidth == 0 || state.klineCtrlHeight == 0 || state.klines.isEmpty) {
          return Container(
            width: size.width,
            height: size.height,
            color: const Color.fromARGB(255, 24, 24, 24),
          );
        }
        // updateSize(size); // 计算K线图宽高,当前显示的K线图范围
        return Stack(
          children: [
            Column(
              children: [
                // K线主图
                KlineChart(stockColors: stockColors, shareCode: state.shareCode),
                // 技术指标图
                ..._buildIndicators(context, state, stockColors),
              ],
            ),
            // 十字线
            Positioned(
              left: state.klineChartLeftMargin,
              top: state.klineCtrlTitleBarHeight * 2 - KlineCtrlLayout.titleBarMargin,
              child: CrossLineChart(stockColors: stockColors),
            ),
            // 日K线详情
            KlineInfoPanel(),
          ],
        );
      },
    );
  }

  // 技术指标副图组件
  List<Widget> _buildIndicators(
    BuildContext context,
    KlineCtrlState klineCtrlState,
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

  // 键盘上/下/左/右/Escape/Home/End功能键 事件响应
  KeyEventResult _onKeyEvent(FocusNode focusNode, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      // 提前获取 notifier 和 state，避免重复读取
      final notifier = ref.read(gridKlineCtrlProviders(widget.shareCode).notifier);
      final state = ref.read(gridKlineCtrlProviders(widget.shareCode));
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          notifier.keyDownArrowLeft();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowRight:
          notifier.keyDownArrowRight();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowUp:
          notifier.zoomIn();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowDown:
          notifier.zoomOut();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.escape:
          notifier.hideCrossLine();
          notifier.showKlineInfoCtrl(false);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.home:
          notifier.updateCrossLine(
            mode: CrossLineMode.followKline,
            klineIndex: state.klineRng.begin,
          );
          notifier.showKlineInfoCtrl(true);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.end:
          notifier.updateCrossLine(mode: CrossLineMode.followKline, klineIndex: state.klineRng.end);
          notifier.showKlineInfoCtrl(true);
          return KeyEventResult.handled;
        default:
          return KeyEventResult.ignored;
      }
    } else if (event is KeyUpEvent) {
      Set<LogicalKeyboardKey> handledKeys = {
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.escape,
        LogicalKeyboardKey.home,
        LogicalKeyboardKey.end,
      };
      return handledKeys.contains(event.logicalKey)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  /// 用户单击鼠标的时候也需要记住单击位置所在的K线下标，以此为中心点进行缩放
  void _onTapDown(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    // 计算点击的K线索引
    final notifier = ref.read(klineCtrlProvider.notifier);
    notifier.updateCrossLine(mode: CrossLineMode.followCursor, pos: localPosition);
    notifier.showKlineInfoCtrl(true);
  }

  /// 鼠标移动事件
  void _onPointerHover(PointerEvent event) {
    _onMouseMove(event.localPosition);
  }

  // 鼠标移动的时候需要动态绘制十字光标
  void _onMouseMove(Offset localPosition) {
    ref.read(klineCtrlProvider.notifier).updateCrossLine(pos: localPosition);
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
