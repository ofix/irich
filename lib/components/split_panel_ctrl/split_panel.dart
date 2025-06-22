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

  ///
  // 转换为JSON
  Map<String, dynamic> serialize() => {'GroupId': groupId};
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
