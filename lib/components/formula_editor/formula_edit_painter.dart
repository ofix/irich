// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/formula_editor/formula_editor_painter.dart
// Purpose:     formula editor painter
// Author:      songhuabiao
// Created:     2025-06-23 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/formula_editor/chunk_table.dart';

class FormulaEditorPainter extends CustomPainter {
  final RichDoc doc;
  FormulaEditorPainter({required this.doc});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // 绘制可见行（计算行号范围）
    for (int line = doc.visibleBeginLine; line < doc.visibleEndLine; line++) {
      final lineText = doc.getLine(line);
      textPainter.text = TextSpan(
        text: lineText,
        style: TextStyle(fontFamily: 'Monospace', fontSize: 14),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, line * doc.lineHeight));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
