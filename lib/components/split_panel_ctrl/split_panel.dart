// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/split_panel_ctrl/split_panel.dart
// Purpose:     split panel class definition
// Author:      songhuabiao
// Created:     2025-06-17 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';

enum SplitPanelType { leaf, row, column, none }

enum DragMode { absolute, relative }

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

// 动态面板节点
class SplitPanel {
  SplitPanelType type; // "Leaf" | "Row" | "Column"
  int id;
  double percent;
  int? groupId;
  Rect rect; // 归一化矩形
  List<SplitPanel> children;
  Widget? widget;

  SplitPanel({
    this.type = SplitPanelType.leaf,
    required this.rect,
    this.percent = 1,
    this.id = 0,
    this.groupId,
    this.children = const [],
    this.widget,
  });

  bool get bindWidget => widget != null;

  // 深拷贝
  SplitPanel.deepCopy(SplitPanel other)
    : type = other.type,
      rect = other.rect,
      id = other.id,
      percent = other.percent,
      groupId = other.groupId,
      children = other.children.map((c) => SplitPanel.deepCopy(c)).toList(),
      widget = other.widget;

  // 转换为JSON
  Map<String, dynamic> toJson() => {
    'Type': type == SplitPanelType.leaf ? widget.runtimeType.toString() : type,
    'Percent': percent,
    if (groupId != null) 'GroupId': groupId,
    if (children.isNotEmpty) 'Children': children.map((c) => c.toJson()).toList(),
  };
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

class DynamicSplitLine {
  final bool isHorizontal; // true: 横向, false: 竖向
  double position; // 横向线: y坐标; 竖向线: x坐标
  double start; // 起点 (横向: x_min; 竖向: y_min)
  double end; // 终点 (横向: x_max; 竖向: y_max)
  bool isSelected; // 是否用户当前选中
  SplitPanel firstPanel; // 分割线的左面板或者上面板
  SplitPanel secondPanel; // 分割线的右面板或者下面板

  DynamicSplitLine({
    required this.isHorizontal,
    required this.position,
    required this.start,
    required this.end,
    required this.firstPanel,
    required this.secondPanel,
    this.isSelected = false,
  });
}
