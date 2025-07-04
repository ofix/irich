// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/split_view.dart
// Purpose:     split view recursively
// Author:      songhuabiao
// Created:     2025-07-04 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';

enum SplitDirection { horizontal, vertical }

class SplitView extends StatefulWidget {
  final List<Widget> children;
  final SplitDirection direction;
  final List<double> weights; // 初始权重比例
  final double dividerThickness;
  final Color dividerColor;
  final Function(int index, double weight)? onWeightChanged;

  const SplitView({
    super.key,
    required this.children,
    this.direction = SplitDirection.horizontal,
    this.weights = const [],
    this.dividerThickness = 5.0,
    this.dividerColor = Colors.grey,
    this.onWeightChanged,
  });

  @override
  State<SplitView> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  late List<double> _weights;
  late List<double> _dividerPositions;
  double _totalSize = 0.0;

  @override
  void initState() {
    super.initState();
    _initWeights();
  }

  // 初始化权重
  void _initWeights() {
    if (widget.weights.isNotEmpty && widget.weights.length == widget.children.length) {
      _weights = List<double>.from(widget.weights);
    } else {
      // 默认平均分配
      _weights = List.generate(widget.children.length, (_) => 1.0 / widget.children.length);
    }
    _updateDividerPositions();
  }

  // 更新分割线位置
  void _updateDividerPositions() {
    _dividerPositions = [];
    double currentPosition = 0.0;
    for (int i = 0; i < _weights.length - 1; i++) {
      currentPosition += _weights[i] * _totalSize;
      _dividerPositions.add(currentPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _totalSize =
            widget.direction == SplitDirection.horizontal
                ? constraints.maxWidth
                : constraints.maxHeight;
        _updateDividerPositions();

        final childrenWithDividers = <Widget>[];
        for (int i = 0; i < widget.children.length; i++) {
          childrenWithDividers.add(
            Expanded(flex: (_weights[i] * 100).round(), child: widget.children[i]),
          );
          // 最后一个子组件后不添加分割线
          if (i < widget.children.length - 1) {
            childrenWithDividers.add(_buildDivider(i));
          }
        }

        return widget.direction == SplitDirection.horizontal
            ? Row(children: childrenWithDividers)
            : Column(children: childrenWithDividers);
      },
    );
  }

  // 构建可拖动的分割线
  Widget _buildDivider(int index) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          final delta =
              widget.direction == SplitDirection.horizontal ? details.delta.dx : details.delta.dy;
          _adjustWeights(index, delta);
        });
      },
      child: Container(
        width: widget.direction == SplitDirection.horizontal ? widget.dividerThickness : null,
        height: widget.direction == SplitDirection.vertical ? widget.dividerThickness : null,
        color: widget.dividerColor,
      ),
    );
  }

  // 调整权重
  void _adjustWeights(int index, double delta) {
    if (_totalSize <= 0) return;

    // 计算变化比例
    final ratio = delta / _totalSize;
    final minWeight = 0.1; // 最小权重限制

    // 确保调整后两个区域的权重都不小于最小值
    if (_weights[index] - ratio >= minWeight && _weights[index + 1] + ratio >= minWeight) {
      _weights[index] -= ratio;
      _weights[index + 1] += ratio;

      // 触发回调
      widget.onWeightChanged?.call(index, _weights[index]);
      widget.onWeightChanged?.call(index + 1, _weights[index + 1]);
    }
  }
}
