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

// 分割节点抽象类
abstract class SplitNode {
  SplitNode();
}

// 分割线（横向分割线｜垂直分割线）
class SplitLine extends SplitNode {
  final bool isHorizontal; // true: 横向, false: 竖向
  double position; // 横向线: y坐标; 竖向线: x坐标
  double start; // 起点 (横向: x_min; 竖向: y_min)
  double end; // 终点 (横向: x_max; 竖向: y_max)
  bool isSelected; // 是否用户当前选中
  SplitContainer firstPanel; // 分割线的左面板或者上面板
  SplitContainer secondPanel; // 分割线的右面板或者下面板

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

abstract class SplitContainer {
  Rect rect;
  double percent;
  List<SplitContainer> children;
  List<SplitLine> lines;
  SplitContainer? parent;
  int pos;
  SplitContainer({
    required this.rect,
    this.percent = 1,
    this.children = const [],
    this.lines = const [],
    this.pos = 0,
  });
}

// 横向分割容器
class SplitRow extends SplitContainer {
  SplitRow({required super.rect, super.percent, super.children, super.lines});
}

class SplitColumn extends SplitContainer {
  SplitColumn({required super.rect, super.percent, super.children, super.lines});
}

// 分割面板节点
class SplitPanel extends SplitContainer {
  int groupId;
  Widget? widget;

  SplitPanel({required super.rect, super.percent, super.children, this.groupId = 0, this.widget});

  bool get bindWidget => widget != null;

  // 深拷贝
  SplitPanel.deepCopy(SplitPanel other)
    : groupId = other.groupId,
      widget = other.widget,
      super(
        rect: Rect.fromLTWH(other.rect.left, other.rect.top, other.rect.width, other.rect.height),
        percent: other.percent,
        children: other.children,
      );

  // 转换为JSON
  Map<String, dynamic> toJson() => {'GroupId': groupId};
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
