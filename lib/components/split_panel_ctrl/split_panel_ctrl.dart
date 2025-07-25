// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/split_panel_ctrl/split_panel_ctrl.dart
// Purpose:     split panel ctrl
// Author:      songhuabiao
// Created:     2025-06-17 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irich/components/split_panel_ctrl/split_panel.dart';
import 'package:irich/components/split_panel_ctrl/split_panel_chart.dart';
import 'package:irich/components/split_panel_ctrl/split_panel_layout.dart';

enum Direction { up, down, left, right }

// 自定义组件
class CustomWidget {
  String zhName;
  String name;
  CustomWidget(this.zhName, this.name);
}

// 分组颜色
class WidgetGroupColor {
  int groupId;
  Color groupColor;
  WidgetGroupColor(this.groupId, this.groupColor);
}

class SplitPanelCtrl extends ConsumerStatefulWidget {
  const SplitPanelCtrl({super.key});

  @override
  ConsumerState<SplitPanelCtrl> createState() => _SplitPanelCtrlState();
}

class _SplitPanelCtrlState extends ConsumerState<SplitPanelCtrl> {
  final SplitPanelLayout layout = SplitPanelLayout();
  Offset mousePos = Offset.zero; // 拖拽过程进行偏移位置的计算
  bool isLeftBtnDown = false;
  bool isCtrlPressed = false;
  DragMode dragMode = DragMode.relative;
  bool inDragging = false;

  Size oldSize = Size(0, 0); // 老的窗口大小
  MouseCursor cursor = SystemMouseCursors.basic;
  Map<String, SplitMode> splitHash = {
    "vertical": SplitMode.vertical,
    "horizontal": SplitMode.horizontal,
    "rows_3": SplitMode.rows_3,
    "cols_3": SplitMode.cols_3,
    "grid_2x2": SplitMode.grid_2_2,
    "grid_4x4": SplitMode.grid_4_4,
  };
  final FocusNode focusNode = FocusNode(); // 替代RawKeyboardListener

  List<CustomWidget> customWidgets = [
    CustomWidget("自选股", "WatchList"),
    CustomWidget("沪深京个股", "MarketList"),
    CustomWidget("沪深板块", "BkList"), // 全部板块，行业板块，概念板块，地域板块，行业分类，概念分类，风格分类
    CustomWidget("沪深京指数", "IndexList"),
    CustomWidget("分时K线(简)", "MinuteKlineSimple"),
    CustomWidget("分时K线(全)", "MinuteKline"),
    CustomWidget("沪深板块成分股", "BkDetail"),
    CustomWidget("多周期同列", "MultiPeiriod"),
    // CustomWidget("资讯公告", "News"),
  ];

  List<WidgetGroupColor> widgetGroupColors = [
    WidgetGroupColor(0, Color.fromARGB(255, 255, 20, 20)),
    WidgetGroupColor(1, Color.fromARGB(255, 20, 255, 251)),
    WidgetGroupColor(2, Color.fromARGB(255, 106, 63, 199)),
    WidgetGroupColor(3, Color.fromARGB(255, 184, 101, 12)),
    WidgetGroupColor(4, Color.fromARGB(255, 4, 192, 76)),
    WidgetGroupColor(5, Color.fromARGB(255, 255, 20, 173)),
    WidgetGroupColor(6, Color.fromARGB(255, 18, 38, 154)),
    WidgetGroupColor(7, Color.fromARGB(255, 101, 18, 18)),
    WidgetGroupColor(8, Color.fromARGB(255, 54, 2, 2)),
    WidgetGroupColor(8, Color.fromARGB(255, 184, 255, 20)),
    WidgetGroupColor(9, Color.fromARGB(255, 139, 6, 94)),
  ];

  @override
  void initState() {
    super.initState();
    // 监听全局键盘事件
    HardwareKeyboard.instance.addHandler(handleKeyEvent); // 新API
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(handleKeyEvent);
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      focusNode: focusNode,
      child: Column(
        children: [
          _buildToolBar(), // 工具栏（无事件监听）
          Expanded(
            child: MouseRegion(
              cursor: cursor,
              onHover: onMouseHover,
              child: Listener(
                // onPointerSignal: _onMouseScroll,
                onPointerMove: onMouseMove,
                onPointerDown: onMouseLeftDown,
                onPointerUp: onMouseUp,
                child: _buildPanel(layout),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onMouseHover(PointerHoverEvent event) {
    mousePos = event.localPosition;
    // 进行分割线检测
    layout.onSplitLinesHitTest(mousePos);
    // 2. 动态更新光标
    final line = layout.activeSplitLine;
    if (line != null) {
      cursor =
          line.isHorizontal
              ? SystemMouseCursors
                  .resizeRow // 横向分割线
              : SystemMouseCursors.resizeColumn; // 竖向分割线
    } else {
      cursor = SystemMouseCursors.basic;
    }
    setState(() {});
  }

  // 光标移动事件回调
  void onMouseMove(PointerMoveEvent event) {
    if (inDragging) {
      layout.dragSplitLine(layout.activeSplitLine!, event.localDelta);
    }
    setState(() {});
  }

  void onMouseUp(PointerUpEvent event) {
    inDragging = false;
    isLeftBtnDown = false;
    layout.printSplitTree();
    setState(() {});
  }

  // 鼠标左键按下事件回调
  void onMouseLeftDown(PointerDownEvent event) {
    if (event.buttons == kPrimaryButton) {
      isLeftBtnDown = true;
      if (layout.activeSplitLine != null) {
        inDragging = true; // 开始拖拽了
      }
      layout.onPanelSelected(event.localPosition);
      setState(() {});
    }
  }

  Widget _buildToolBar() {
    List<String> svgs = ['vertical', 'horizontal', 'rows_3', 'cols_3', 'grid_2x2', 'grid_4x4'];
    List<String> names = ['水平', "垂直", "横向3等分", "竖向3等分", "2X2网格", "4X4网格"];

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 138, 137, 137),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(svgs.length, (index) {
              return Tooltip(
                message: names[index], // 提示文字
                waitDuration: Duration(milliseconds: 500), // 悬停1秒后显示
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        hoverColor: const Color.fromARGB(255, 228, 226, 226),
                        onPressed: () => onClickLayoutButton(svgs[index]),
                        icon: SvgPicture.asset('images/${svgs[index]}.svg', width: 32, height: 32),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void onClickLayoutButton(String svg) {
    final splitMode = splitHash[svg];
    layout.splitPanel(splitMode!);
    setState(() {});
  }

  Widget _buildPanel(SplitPanelLayout layout) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        Size size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size != oldSize) {
          // 窗口调整的时候重新布局
          layout.forceLayout(layout.root, Rect.fromLTWH(0, 0, size.width, size.height));
          oldSize = size;
        }
        return SplitPanelChart(width: size.width, height: size.height, layout: layout);
      },
    );
  }

  bool handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyUpEvent) {
      setState(() {
        isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
      });

      // 处理Ctrl+方向键
      if (isCtrlPressed && event is KeyDownEvent) {
        handleArrowKey(event.logicalKey);
      }
    }
    return false; // 不阻止事件继续传播
  }

  void handleArrowKey(LogicalKeyboardKey key) {
    final String direction = switch (key) {
      LogicalKeyboardKey.arrowUp => '上',
      LogicalKeyboardKey.arrowDown => '下',
      LogicalKeyboardKey.arrowLeft => '左',
      LogicalKeyboardKey.arrowRight => '右',
      _ => '其他',
    };
    if (direction != '其他') {
      debugPrint('Ctrl+$direction 被按下');
      // 在此添加业务逻辑
    }
  }
}
