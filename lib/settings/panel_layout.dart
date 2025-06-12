// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/settings/panel_layout.dart
// Purpose:     panel layout
// Author:      songhuabiao
// Created:     2025-06-12 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

// 面板
import 'package:flutter/widgets.dart';

abstract class LayoutNode {
  const LayoutNode();

  Widget build(BuildContext context);

  // 用于序列化的方法
  Map<String, dynamic> toJson();
}

class Rows extends LayoutNode {
  final List<LayoutNode> children;
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const Rows({
    required this.children,
    this.spacing = 0.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  factory Rows.builder({
    double spacing = 0.0,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    required List<LayoutNode> Function(RowsBuilder) children,
  }) {
    final builder = RowsBuilder();
    final childNodes = children(builder);
    return Rows(
      children: childNodes,
      spacing: spacing,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < children.length - 1 ? spacing : 0),
            child: children[i].build(context),
          ),
      ],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'rows',
      'spacing': spacing,
      'mainAxisAlignment': mainAxisAlignment.toString(),
      'crossAxisAlignment': crossAxisAlignment.toString(),
      'children': children.map((c) => c.toJson()).toList(),
    };
  }
}

class Cols extends LayoutNode {
  final List<LayoutNode> children;
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const Cols({
    required this.children,
    this.spacing = 0.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  factory Cols.builder({
    double spacing = 0.0,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    required List<LayoutNode> Function(ColsBuilder) children,
  }) {
    final builder = ColsBuilder();
    final childNodes = children(builder);
    return Cols(
      children: childNodes,
      spacing: spacing,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++)
          Padding(
            padding: EdgeInsets.only(right: i < children.length - 1 ? spacing : 0),
            child: children[i].build(context),
          ),
      ],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'cols',
      'spacing': spacing,
      'mainAxisAlignment': mainAxisAlignment.toString(),
      'crossAxisAlignment': crossAxisAlignment.toString(),
      'children': children.map((c) => c.toJson()).toList(),
    };
  }
}

class RowsBuilder {
  List<LayoutNode> _children = [];

  void add(LayoutNode node) {
    _children.add(node);
  }

  void addAll(Iterable<LayoutNode> nodes) {
    _children.addAll(nodes);
  }

  List<LayoutNode> build() => _children;
}

class ColsBuilder {
  List<LayoutNode> _children = [];

  void add(LayoutNode node) {
    _children.add(node);
  }

  void addAll(Iterable<LayoutNode> nodes) {
    _children.addAll(nodes);
  }

  List<LayoutNode> build() => _children;
}

class LayoutItem extends LayoutNode {
  final String id;
  final WidgetBuilder builder;

  const LayoutItem({required this.id, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context);
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'item', 'id': id};
  }
}
