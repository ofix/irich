// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/panels/day_kline_rich_panel.dart
// Purpose:     day kline rich panel
// Author:      songhuabiao
// Created:     2025-07-02 20:30
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
import 'package:irich/components/kline_ctrl/kline_info_panel.dart';
import 'package:irich/components/panels/rich_panel.dart';
import 'package:irich/components/rich_radio_button_group.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/provider_rich_panel.dart';
import 'package:irich/store/state_quote.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/theme/stock_colors.dart';

// 股票日K线图
class DayKlineRichPanel extends RichPanel {
  const DayKlineRichPanel({super.key, required super.name, super.groupId = 0});
  @override
  ConsumerState<DayKlineRichPanel> createState() => _DayKlineRichPanelState();
}

class _DayKlineRichPanelState extends ConsumerState<DayKlineRichPanel> {
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
  late final FocusNode _focusNode;
  @override
  void initState() {
    super.initState();
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
    // ref.watch(currentShareCodeProvider);
    // ref.watch(watchShareListProvider);
    // 监听指定名称的面板的指定数据
    ref.watch(
      richPanelProviders(RichPanelParams(name: widget.name, groupId: widget.groupId)).select(
        (s) => (
          s['dayKline']['klineCtrlWidth'],
          s['dayKline']['klineCtrlHeight'],
          s['dayKline']['klineStep'],
          s['dayKline']['klineRng.begin'],
          s['dayKline']['klineType'],
          s['dayKline']['minuteWndMode'],
          s['dayKline']['dataLoaded'],
        ),
      ),
    );

    final stockColors = Theme.of(context).extension<StockColors>()!;
    final klineCtrlState = ref.read(
      richPanelProviders(
        RichPanelParams(name: widget.name, groupId: widget.groupId),
      ).select((s) => s['dayKline']),
    );
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
            child: buildKlineCtrl(stockColors, klineCtrlState),
          ),
        ),
      ),
    );
  }

  Widget buildKlineCtrl(StockColors stockColors, KlineCtrlState state) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // final parentWidth = constraints.maxWidth; // 父容器可用宽度
        Size size = Size(constraints.maxWidth, constraints.maxHeight);
        final notifier = ref.read(
          richPanelProviders(RichPanelParams(name: widget.name, groupId: widget.groupId)).notifier,
        );
        if (size.width != state.klineCtrlWidth || size.height != state.klineCtrlHeight) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifier.updatePanelState('dayKline', 'updateLayoutSize', {'Size': size});
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
                // K线类型切换
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [_buildKlineName(state.share!.name), _buildKlineTypeTabs()]),
                    Row(
                      children: [
                        _buildMinuteKlineWndMode(state), // 分时窗口模式选择
                        SizedBox(width: 8),
                        _buildFavoriteButton(state, stockColors), // 自选按钮
                      ],
                    ),
                  ],
                ),
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

  /// 股票名称组件
  Widget _buildKlineName(String shareName) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8), // 左右各16像素
      child: Text(
        shareName,
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

  Widget _buildMinuteKlineWndMode(KlineCtrlState klineState) {
    if (klineState.klineType.isMinuteType) {
      return DropdownButtonHideUnderline(
        child: DropdownButton<MinuteKlineWndMode>(
          value: klineState.minuteWndMode,
          hint: Text('请选择模式'),
          items:
              MinuteKlineWndMode.values.map((mode) {
                return DropdownMenuItem<MinuteKlineWndMode>(
                  value: mode,
                  child: Text(mode.displayName),
                );
              }).toList(),
          onChanged: (newMode) {
            if (newMode != null) {
              debugPrint("newMode: ${newMode.displayName}");
              ref
                  .read(
                    richPanelProviders(
                      RichPanelParams(name: widget.name, groupId: widget.groupId),
                    ).notifier,
                  )
                  .updatePanelState('minuteKline', 'changeMinuteWndMode', {'newMode': newMode});
            }
          },
          //dropdownColor: Colors.transparent, // Remove dropdown background color
          icon: Icon(Icons.arrow_drop_down), // Custom icon if needed
          style: TextStyle(
            color: Colors.blue, // Custom text color
            // Add other text styling as needed
          ),
          elevation: 0, // Remove shadow
        ),
      );
    }
    return Container();
  }

  // 自选按钮组件
  Widget _buildFavoriteButton(KlineCtrlState klineState, StockColors stockColors) {
    return // 自选按钮
    MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _onToggleFavoriteButton,
        child: Row(
          children: [
            Icon(
              klineState.share!.isFavorite ? Icons.remove : Icons.add,
              size: 18,
              color: stockColors.hilight,
            ),
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

  /// 添加股票到自选池
  void _onToggleFavoriteButton() {
    final shareCode = ref.read(currentShareCodeProvider);
    Share share = StoreQuote.query(shareCode)!;
    share.isFavorite = !share.isFavorite;
    if (share.isFavorite) {
      ref.read(watchShareListProvider.notifier).add(shareCode);
    } else {
      ref.read(watchShareListProvider.notifier).remove(shareCode);
    }
  }

  /// 切换股票类别
  void _onKlineTypeChanged(String value) async {
    final klineType = klineTypeMap[value]!;
    ref
        .read(
          richPanelProviders(RichPanelParams(name: widget.name, groupId: widget.groupId)).notifier,
        )
        .updatePanelState('dayKline', 'changeKlineType', {'klineType': klineType});
  }

  // 键盘上/下/左/右/Escape/Home/End功能键 事件响应
  KeyEventResult _onKeyEvent(FocusNode focusNode, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      // 提前获取 notifier 和 state，避免重复读取
      final notifier = ref.read(
        richPanelProviders(RichPanelParams(name: widget.name, groupId: widget.groupId)).notifier,
      );
      final state = ref.read(
        richPanelProviders(RichPanelParams(name: widget.name, groupId: widget.groupId)),
      );
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          notifier.updatePanelState('dayKline', 'keydownArrowLeft', {});
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowRight:
          notifier.updatePanelState('dayKline', 'keyDownArrowRight', {});
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowUp:
          notifier.updatePanelState('dayKline', 'zoomIn', {});
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowDown:
          notifier.updatePanelState('dayKline', 'zoomOut', {});

          return KeyEventResult.handled;
        case LogicalKeyboardKey.escape:
          notifier.updatePanelState('dayKline', 'hideCrossLine', {});
          notifier.updatePanelState('dayKline', 'showKlineInfoCtrl', {'visible': false});
          return KeyEventResult.handled;
        case LogicalKeyboardKey.home:
          notifier.updatePanelState('dayKline', 'updateCrossLine', {
            'mode': CrossLineMode.followKline,
            'klineIndex': state['dayKline']['klineRng.begin'],
          });
          notifier.updatePanelState('dayKline', 'showKlineInfoCtrl', {'visible': true});
          return KeyEventResult.handled;
        case LogicalKeyboardKey.end:
          notifier.updatePanelState('dayKline', 'updateCrossLine', {
            'mode': CrossLineMode.followKline,
            'klineIndex': state['dayKline']['klineRng.end'],
          });
          notifier.updatePanelState('dayKline', 'showKlineInfoCtrl', {'visible': true});
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
    ref
        .read(
          richPanelProviders(RichPanelParams(name: widget.name, groupId: widget.groupId)).notifier,
        )
        .updatePanelState('dayKline', 'updateCrossLine', {
          'mode': CrossLineMode.followCursor,
          'pos': localPosition,
        });
  }

  /// 鼠标移动事件
  void _onPointerHover(PointerEvent event) {
    _onMouseMove(event.localPosition);
  }

  // 鼠标移动的时候需要动态绘制十字光标
  void _onMouseMove(Offset localPosition) {
    ref
        .read(
          richPanelProviders(RichPanelParams(name: widget.name, groupId: widget.groupId)).notifier,
        )
        .updatePanelState('dayKline', 'updateCrossLine', {'pos': localPosition});
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
