// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/dynamic_panel_ctrl/dynamic panel.dart
// Purpose:     dynamic panel tree node
// Author:      songhuabiao
// Created:     2025-06-17 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';

enum DynamicPanelType { leaf, row, column, none }

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
class DynamicPanel {
  DynamicPanelType type; // "Leaf" | "Row" | "Column"
  int id;
  double percent;
  int? groupId;
  Rect rect;
  List<DynamicPanel> children;
  Widget? widget;

  DynamicPanel({
    this.type = DynamicPanelType.leaf,
    required this.rect,
    this.percent = 1,
    this.id = 0,
    this.groupId,
    this.children = const [],
    this.widget,
  });

  bool get bindWidget => widget != null;

  // 深拷贝
  DynamicPanel.deepCopy(DynamicPanel other)
    : type = other.type,
      rect = other.rect,
      id = other.id,
      percent = other.percent,
      groupId = other.groupId,
      children = other.children.map((c) => DynamicPanel.deepCopy(c)).toList(),
      widget = other.widget;

  // 转换为JSON
  Map<String, dynamic> toJson() => {
    'Type': type == DynamicPanelType.leaf ? widget.runtimeType.toString() : type,
    'Percent': percent,
    if (groupId != null) 'GroupId': groupId,
    if (children.isNotEmpty) 'Children': children.map((c) => c.toJson()).toList(),
  };
}

// 操作历史记录
class OperationHistory {
  List<DynamicPanel> _stack = [];
  int _currentIndex = -1;

  void push(DynamicPanel state) {
    _stack = _stack.sublist(0, _currentIndex + 1);
    _stack.add(DynamicPanel.deepCopy(state));
    _currentIndex = _stack.length - 1;
  }

  DynamicPanel? get undo => _currentIndex > 0 ? _stack[--_currentIndex] : null;
  DynamicPanel? get redo => _currentIndex < _stack.length - 1 ? _stack[++_currentIndex] : null;
  DynamicPanel get current => _stack[_currentIndex];
}
