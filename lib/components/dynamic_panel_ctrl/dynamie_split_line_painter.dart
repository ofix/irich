// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/dynamic_panel_ctrl/dynamie_split_line_painter.dart
// Purpose:     split line for dynamic panel
// Author:      songhuabiao
// Created:     2025-06-17 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/dynamic_panel_ctrl/dynamic_panel_layout.dart';
import 'package:irich/components/dynamic_panel_ctrl/dynamic_split_line.dart';

class DynamicSplitLinePainter extends CustomPainter {
  final List<DynamicSplitLine> horizontalLines;
  final List<DynamicSplitLine> verticalLines;
  final Color lineColor;
  final double lineWidth;

  DynamicSplitLinePainter({
    required this.horizontalLines,
    required this.verticalLines,
    this.lineColor = Colors.grey,
    this.lineWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = lineColor
          ..strokeWidth = lineWidth;

    // 绘制横向线
    for (final line in horizontalLines) {
      canvas.drawLine(Offset(line.start, line.position), Offset(line.end, line.position), paint);
    }

    // 绘制竖向线
    for (final line in verticalLines) {
      canvas.drawLine(Offset(line.position, line.start), Offset(line.position, line.end), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 在 Flutter 中使用
class DynamicSplitLineWidget extends StatelessWidget {
  final DynamicPanelLayout layout;

  const DynamicSplitLineWidget({super.key, required this.layout});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DynamicSplitLinePainter(
        horizontalLines: layout.horizontalLines,
        verticalLines: layout.verticalLines,
      ),
      size: Size.infinite, // 填充父容器
    );
  }
}
