// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/split_panel_ctrl/split_panel_painter.dart
// Purpose:     split panel painter
// Author:      songhuabiao
// Created:     2025-06-06 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/split_panel_ctrl/split_panel.dart';

class SplitPanelPainter extends CustomPainter {
  SplitPanel root; // 面板树
  SplitPanel? selectedPanel; // 当前选中的面板
  SplitLine? selectedSplitLine; // 当前选中的分割线
  List<SplitLine> horizontalLines; // 横向分割线列表
  List<SplitLine> verticalLines; // 竖向分割线列表

  SplitPanelPainter({
    required this.root,
    required this.selectedPanel,
    required this.selectedSplitLine,
    required this.horizontalLines,
    required this.verticalLines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pen =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
    final activePen =
        Paint()
          ..color = const Color.fromARGB(255, 246, 177, 3)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    // 绘制根节点
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), pen);

    // 绘制横向分割线
    for (final line in horizontalLines) {
      if (!line.isSelected) {
        canvas.drawLine(Offset(line.start, line.position), Offset(line.end, line.position), pen);
      }
    }

    // 绘制竖向分割线
    for (final line in verticalLines) {
      if (!line.isSelected) {
        canvas.drawLine(Offset(line.position, line.start), Offset(line.position, line.end), pen);
      }
    }

    // 绘制选中的矩形
    if (selectedPanel != null) {
      canvas.drawRect(selectedPanel!.rect, activePen);
    }
    // 绘制选中的分割线
    if (selectedSplitLine != null) {
      if (selectedSplitLine!.isHorizontal) {
        canvas.drawLine(
          Offset(selectedSplitLine!.start, selectedSplitLine!.position),
          Offset(selectedSplitLine!.end, selectedSplitLine!.position),
          activePen,
        );
      } else {
        canvas.drawLine(
          Offset(selectedSplitLine!.position, selectedSplitLine!.start),
          Offset(selectedSplitLine!.position, selectedSplitLine!.end),
          activePen,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) {
    if (old is! SplitPanelPainter) return true;

    if (horizontalLines != old.horizontalLines || verticalLines != old.verticalLines) {
      return true;
    }

    // 比较基础类型和引用
    return false;
  }
}
