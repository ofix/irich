// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/formula_engine/formula_edit_ctrl.dart
// Purpose:     formula edit ctrl
// Author:      songhuabiao
// Created:     2025-06-23 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:irich/components/formula_editor/chunk_table.dart';
import 'package:irich/components/formula_editor/formula_edit_painter.dart';

class FormulaEditCtrl extends StatefulWidget {
  const FormulaEditCtrl({super.key});
  @override
  State<FormulaEditCtrl> createState() => _EditorWidgetState();
}

class _EditorWidgetState extends State<FormulaEditCtrl> {
  final FocusNode _focusNode = FocusNode();
  final RichDoc _doc = RichDoc();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _handleTap(details.localPosition),
      child: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: _handleKeyEvent,
        child: CustomPaint(painter: FormulaEditorPainter(doc: _doc), size: Size.infinite),
      ),
    );
  }

  void _handleTap(Offset position) {
    final line = (position.dy / _doc.lineHeight).floor();
    final column = getColumnWidth() > 0 ? (position.dx / getColumnWidth()).floor() : 0;
    _doc.setCursorPosition(line, column);
  }

  int getColumnWidth() {
    // 假设每个字符宽度为8像素
    return 8;
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        _doc.deleteChar();
      } else if (event.character != null) {
        _doc.insertWord(event.character!);
      }
    }
  }
}
