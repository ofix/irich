// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/formula_engine/formula_completer.dart
// Purpose:     stock formula completer
// Author:      songhuabiao
// Created:     2025-06-23 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/components/formula_engine/formula_defines.dart';

class FormulaCompleter {
  final List<FormulaFunction> functions;
  final List<String> fields;
  final String text;
  final int cursorPosition;

  FormulaCompleter({
    required this.functions,
    required this.fields,
    required this.text,
    required this.cursorPosition,
  });

  List<CompletionItem> getCompletions() {
    final completions = <CompletionItem>[];

    // 获取当前上下文
    final context = _analyzeContext();

    switch (context.type) {
      case CompletionContextType.functionName:
        completions.addAll(
          functions.map(
            (f) => CompletionItem(
              label: f.name,
              detail: f.description,
              insertText: '${f.name}(${f.parameters.isNotEmpty ? '' : ')'}',
            ),
          ),
        );
        break;

      case CompletionContextType.field:
        completions.addAll(fields.map((f) => CompletionItem(label: f, insertText: f)));
        break;

      case CompletionContextType.functionParam:
        final func = context.function!;
        final paramIndex = context.paramIndex ?? 0;
        // if (paramIndex < func.params.length) {
        //   completions.add(
        //     CompletionItem(
        //       label: func.params[paramIndex],
        //       detail: '${func.name} 的参数',
        //       insertText: func.params[paramIndex],
        //     ),
        //   );
        // }
        break;
    }

    return completions;
  }

  CompletionContext _analyzeContext() {
    if (cursorPosition > text.length) return CompletionContext();

    // 简单分析 - 实际需要更复杂的语法分析
    final lastWord = _getLastWord();

    // 如果在函数括号内
    final openParenIndex = text.lastIndexOf('(', cursorPosition);
    if (openParenIndex != -1) {
      final beforeParen = text.substring(0, openParenIndex).trim();
      final lastSpace = beforeParen.lastIndexOf(' ') + 1;
      final funcName = beforeParen.substring(lastSpace);

      final func = functions.firstWhere(
        (f) => f.name == funcName,
        orElse:
            () => FormulaFunction(
              name: '',
              description: '',
              parameters: [],
              returnType: FormulaType.boolean,
            ),
      );

      if (func.name.isNotEmpty) {
        // 计算当前是第几个参数
        final afterParen = text.substring(openParenIndex + 1, cursorPosition);
        final paramIndex = ','.allMatches(afterParen).length;

        return CompletionContext(
          type: CompletionContextType.functionParam,
          function: null,
          paramIndex: paramIndex,
        );
      }
    }

    // 检查是否在可能输入函数或字段的位置
    if (lastWord.isEmpty ||
        RegExp(r'[+\-*/%^<>=!&|(,]').hasMatch(text.substring(cursorPosition - 1, cursorPosition))) {
      return CompletionContext(type: CompletionContextType.functionName);
    }

    return CompletionContext(type: CompletionContextType.field);
  }

  String _getLastWord() {
    if (cursorPosition == 0) return '';

    int start = cursorPosition - 1;
    while (start >= 0 && _isIdentifierChar(text[start])) {
      start--;
    }

    return text.substring(start + 1, cursorPosition);
  }

  bool _isIdentifierChar(String char) {
    return RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
  }
}

enum CompletionContextType { functionName, field, functionParam }

class CompletionContext {
  final CompletionContextType type;
  final StockFormula? function;
  final int? paramIndex;

  CompletionContext({this.type = CompletionContextType.field, this.function, this.paramIndex});
}

class CompletionItem {
  final String label;
  final String? detail;
  final String insertText;

  CompletionItem({required this.label, this.detail, required this.insertText});
}
