// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/split_panel_ctrl/split_panel.dart
// Purpose:     split panel class definition
// Author:      songhuabiao
// Created:     2025-06-17 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';

enum SplitType {
  leaf,
  row,
  column,
  none;

  String get name {
    switch (this) {
      case SplitType.leaf:
        return 'leaf';
      case SplitType.row:
        return 'row';
      case SplitType.column:
        return 'column';
      case SplitType.none:
        return 'none';
    }
  }

  static SplitType deserialize(String name) {
    switch (name) {
      case 'leaf':
        return SplitType.leaf;
      case 'row':
        return SplitType.row;
      case 'column':
        return SplitType.column;
      case 'none':
        return SplitType.none;
      default:
        return SplitType.leaf;
    }
  }
}

enum DragMode { absolute, relative }

enum DragDirection { left, top, right, bottom }

extension RectExtensions on Rect {
  Rect copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? width,
    double? height,
  }) {
    return Rect.fromLTRB(
      left ?? this.left,
      top ?? this.top,
      right ?? this.right,
      bottom ?? this.bottom,
    );
  }
}

// 分割线（横向分割线｜垂直分割线）
class SplitLine {
  final bool isHorizontal; // true: 横向, false: 竖向
  double position; // 横向线: y坐标; 竖向线: x坐标
  double start; // 起点 (横向: x_min; 竖向: y_min)
  double end; // 终点 (横向: x_max; 竖向: y_max)
  bool isSelected; // 是否用户当前选中
  SplitPanel firstPanel; // 分割线的左面板或者上面板
  SplitPanel secondPanel; // 分割线的右面板或者下面板
  SplitLine({
    required this.isHorizontal,
    required this.position,
    required this.start,
    required this.end,
    required this.firstPanel,
    required this.secondPanel,
    this.isSelected = false,
  }) : super();

  SplitLine.deepCopy(SplitLine other)
    : isHorizontal = other.isHorizontal,
      position = other.position,
      start = other.start,
      end = other.end,
      firstPanel = other.firstPanel,
      secondPanel = other.secondPanel,
      isSelected = other.isSelected,
      super();

  Map<String, dynamic> serialize() {
    return {
      'isHorizontal': isHorizontal,
      'position': position,
      'start': start,
      'end': end,
      'firstPanel': firstPanel.pos,
      'secondPanel': secondPanel.pos,
      'isSelected': false,
    };
  }
}

class SplitPanel {
  SplitType type;
  Rect rect;
  double percent;
  List<SplitPanel> children;
  List<SplitLine> lines;
  SplitPanel? parent;
  int pos;
  int groupId;
  Widget? widget;
  SplitPanel({
    required this.rect,
    this.type = SplitType.leaf,
    this.percent = 1,
    List<SplitPanel>? children,
    List<SplitLine>? lines,
    this.pos = 0,
    this.groupId = 0,
    this.widget,
  }) : children = children ?? [],
       lines = lines ?? [];

  // 序列化为 JSON
  Map<String, dynamic> serialize() {
    return {
      'type': type.name,
      'percent': percent,
      'children': children.map((child) => child.serialize()).toList(),
      'lines': lines.map((line) => line.serialize()).toList(),
      'pos': pos,
      'groupId': groupId,
      'widgetType': widget.runtimeType.toString(),
    };
  }

  factory SplitPanel.deserialize(
    Map<String, dynamic> json, {
    required Rect parentRect,
    required SplitType parentType,
  }) {
    final splitType = SplitType.deserialize(json['type'] as String);
    final percent = json['percent'] ?? 1.0;

    // 根据父容器类型和当前面板类型计算 Rect
    final rect = _calculateRect(
      parentRect: parentRect,
      parentType: parentType,
      currentType: splitType,
      percent: percent,
    );

    final panel = SplitPanel(
      rect: rect,
      type: splitType,
      percent: percent,
      pos: json['pos'] ?? 0,
      groupId: json['groupId'] ?? 0,
      widget: _deserializeWidget(json), // 假设有这个方法来反序列化 widget
    );

    // 递归反序列化子节点
    if (json['children'] != null) {
      panel.children =
          (json['children'] as List)
              .map(
                (childJson) => SplitPanel.deserialize(
                  childJson as Map<String, dynamic>,
                  parentRect: rect,
                  parentType: splitType,
                ),
              )
              .toList();
    }

    // 设置子节点的 parent 引用
    for (final child in panel.children) {
      child.parent = panel;
    }

    return panel;
  }

  static Rect _calculateRect({
    required Rect parentRect,
    required SplitType parentType,
    required SplitType currentType,
    required double percent,
  }) {
    switch (parentType) {
      case SplitType.row:
        // 在行布局中，子元素水平排列
        return Rect.fromLTWH(
          parentRect.left,
          parentRect.top,
          parentRect.width * percent,
          parentRect.height,
        );
      case SplitType.column:
        // 在列布局中，子元素垂直排列
        return Rect.fromLTWH(
          parentRect.left,
          parentRect.top,
          parentRect.width,
          parentRect.height * percent,
        );
      case SplitType.leaf:
      case SplitType.none:
        // 如果是叶子节点或无类型父节点，默认使用父容器的全部空间
        return parentRect;
    }
  }

  // 示例性的 widget 反序列化方法
  static Widget? _deserializeWidget(Map<String, dynamic> json) {
    final widgetType = json['widgetType'];
    final config = json['widgetConfig'];

    if (widgetType == null) return null;

    switch (widgetType) {
      case 'text':
        return Text(config?['content'] ?? '');
      case 'container':
        return Container(
          color: _parseColor(config?['color']),
          child: _deserializeWidget(config?['child']),
        );
      // 添加更多 widget 类型的处理
      default:
        return null;
    }
  }

  static Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    // 简单的颜色解析逻辑
    return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
  }

  SplitPanel.deepCopy(SplitPanel other)
    : groupId = other.groupId,
      widget = other.widget,
      type = other.type,
      pos = other.pos,
      rect = Rect.fromLTWH(other.rect.left, other.rect.top, other.rect.width, other.rect.height),
      percent = other.percent,
      lines = other.lines,
      children = other.children;

  bool get bindWidget => widget != null;
  bool get isLeaf => type == SplitType.leaf;

  /// 分割面板，只有 SplitType.leaf 允许分割
  void split(SplitMode mode) {
    if (!isLeaf) return;
    // 只能对叶子节点进行分割
    List<Rect> splitRects = getSplitRects(rect, mode);
    // 添加所有子面板
    addSplitSubPanels(mode, splitRects);
    // 升级叶子节点为 Row 或者 Column
    upgradeSplitType(mode);
    // 绑定父子关系并赋予子元素位置序号
    _bindSubPanels(this, children);
  }

  /// 将父容器拆分成多个小矩形
  List<Rect> getSplitRects(Rect rect, SplitMode mode) {
    switch (mode) {
      case SplitMode.horizontal:
        return _splitVertically(rect, 2);
      case SplitMode.vertical:
        return _splitHorizontally(rect, 2);
      case SplitMode.cols_3:
        return _splitHorizontally(rect, 3);
      case SplitMode.rows_3:
        return _splitVertically(rect, 3);
      case SplitMode.grid_2_2:
        return _splitGrid(rect, 2, 2);
      case SplitMode.grid_4_4:
        return _splitGrid(rect, 4, 4);
      case SplitMode.none:
        // 不分割，返回原矩形
        return [rect];
    }
  }

  /// 水平分割（创建多列）
  List<Rect> _splitHorizontally(Rect rect, int count) {
    final subWidth = rect.width / count;
    return List.generate(
      count,
      (i) => Rect.fromLTWH(rect.left + i * subWidth, rect.top, subWidth, rect.height),
    );
  }

  /// 垂直分割（创建多行）
  List<Rect> _splitVertically(Rect rect, int count) {
    final subHeight = rect.height / count;
    return List.generate(
      count,
      (i) => Rect.fromLTWH(rect.left, rect.top + i * subHeight, rect.width, subHeight),
    );
  }

  /// 网格分割（创建行和列的矩阵）
  List<Rect> _splitGrid(Rect rect, int cols, int rows) {
    final subWidth = rect.width / cols;
    final subHeight = rect.height / rows;

    return List.generate(cols * rows, (index) {
      final col = index % cols;
      final row = index ~/ cols;
      return Rect.fromLTWH(
        rect.left + col * subWidth,
        rect.top + row * subHeight,
        subWidth,
        subHeight,
      );
    });
  }

  int _getSplitCount(SplitMode mode) {
    return switch (mode) {
      SplitMode.horizontal || SplitMode.vertical => 2,
      SplitMode.rows_3 || SplitMode.cols_3 => 3,
      SplitMode.grid_2_2 => 4,
      SplitMode.grid_4_4 => 16,
      _ => throw ArgumentError('Unsupported split mode: $mode'),
    };
  }

  double _getChildPercent(SplitMode mode) {
    return switch (mode) {
      SplitMode.horizontal || SplitMode.vertical => 0.5,
      SplitMode.rows_3 || SplitMode.cols_3 => 1 / 3,
      SplitMode.grid_2_2 => 0.5,
      SplitMode.grid_4_4 => 0.25,
      _ => throw ArgumentError('Unsupported split mode: $mode'),
    };
  }

  void addSplitSubPanels(SplitMode mode, List<Rect> rects) {
    final splitCount = _getSplitCount(mode);
    final childPercent = _getChildPercent(mode);
    children = _createChildPanels(splitCount, childPercent, rects, mode);
  }

  void _bindSubPanels(SplitPanel parent, List<SplitPanel> children) {
    for (int i = 0; i < children.length; i++) {
      children[i].pos = i;
      children[i].parent = this;
    }
  }

  // 分割面板升级为行或者列
  void upgradeSplitType(SplitMode mode) {
    final newSplitType = switch (mode) {
      SplitMode.horizontal || SplitMode.rows_3 => SplitType.column,
      SplitMode.vertical || SplitMode.cols_3 => SplitType.row,
      SplitMode.grid_2_2 || SplitMode.grid_4_4 => SplitType.column,
      _ => throw ArgumentError('Unsupported split mode: $mode'),
    };

    type = newSplitType;
  }

  List<SplitPanel> _createChildPanels(
    int splitCount,
    double childPercent,
    List<Rect> rects,
    SplitMode mode,
  ) {
    if (mode == SplitMode.grid_2_2 || mode == SplitMode.grid_4_4) {
      return _createGridPanels(splitCount, rects, mode);
    }

    return List.generate(splitCount, (index) {
      return SplitPanel(
        rect: rects[index],
        percent: childPercent,
        widget: index == 0 ? widget : null,
        groupId: groupId,
      );
    });
  }

  List<SplitPanel> _createGridPanels(int splitCount, List<Rect> rects, SplitMode mode) {
    final rows = _getGridRows(mode);
    final rowCount = rows;
    final colCount = rows;
    final rowHeight = rect.height / rowCount;

    final List<SplitPanel> rowPanels = [];

    for (int row = 0; row < rowCount; row++) {
      final top = rect.top + row * rowHeight;
      final startIndex = row * colCount;
      final rowRects = rects.sublist(startIndex, startIndex + colCount);

      final rowPanel = _createRowPanel(
        top: top,
        height: rowHeight,
        percent: 1,
        childrenRects: rowRects,
        hasWidget: row == 0,
      );
      rowPanels.add(rowPanel);
    }

    return rowPanels;
  }

  int _getGridRows(SplitMode mode) {
    return switch (mode) {
      SplitMode.grid_2_2 => 2,
      SplitMode.grid_4_4 => 4,
      _ => throw ArgumentError('Not a grid mode: $mode'),
    };
  }

  SplitPanel _createRowPanel({
    required double top,
    required double height,
    required double percent,
    required List<Rect> childrenRects,
    required bool hasWidget,
  }) {
    List<SplitPanel> subPanels = [];
    final childPercent = percent / childrenRects.length;

    for (int i = 0; i < childrenRects.length; i++) {
      final panel = SplitPanel(
        type: SplitType.leaf,
        rect: childrenRects[i],
        percent: childPercent,
        widget: hasWidget && i == 0 ? widget : null,
        groupId: groupId,
      );
      subPanels.add(panel);
    }
    final splitRow = SplitPanel(
      type: SplitType.row,
      rect: Rect.fromLTWH(rect.left, top, rect.width, height),
      percent: percent,
      children: subPanels,
    );
    _bindSubPanels(splitRow, subPanels);
    return splitRow;
  }
}

// 操作历史记录
class OperationHistory {
  List<SplitPanel> _stack = [];
  int _currentIndex = -1;

  void push(SplitPanel state) {
    _stack = _stack.sublist(0, _currentIndex + 1);
    _stack.add(SplitPanel.deepCopy(state));
    _currentIndex = _stack.length - 1;
  }

  SplitPanel? get undo => _currentIndex > 0 ? _stack[--_currentIndex] : null;
  SplitPanel? get redo => _currentIndex < _stack.length - 1 ? _stack[++_currentIndex] : null;
  SplitPanel get current => _stack[_currentIndex];
}

enum SplitMode {
  none,
  horizontal,
  vertical,
  cols_3,
  rows_3,
  grid_2_2,
  grid_4_4;

  String get name {
    switch (this) {
      case SplitMode.none:
        return 'none';
      case SplitMode.horizontal:
        return 'horizontal';
      case SplitMode.vertical:
        return 'vertical';
      case SplitMode.cols_3:
        return 'cols_3';
      case SplitMode.rows_3:
        return 'rows_3';
      case SplitMode.grid_2_2:
        return 'grid_2x2';
      case SplitMode.grid_4_4:
        return 'grid_4x4';
    }
  }
}
