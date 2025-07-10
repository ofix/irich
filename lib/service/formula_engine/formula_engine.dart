// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/formula_engine/formula_engine.dart
// Purpose:     stock formula engine
// Author:      songhuabiao
// Created:     2025-06-23 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/service/formula_engine/formula_defines.dart';
import 'package:irich/service/formula_engine/formula_lexer.dart';

class FormulaEngine {
  final Map<String, List<double>> _data;

  FormulaEngine([this._data = const {}]);

  Future<bool> evaluate(List<Token> tokens) async {
    final lexer = FormulaLexer(tokens);
    final ast = lexer.parse();

    final evaluator = FormulaEvaluator(_data);
    return evaluator.evaluate(ast) as bool;
  }
}

class FormulaEvaluator implements AstVisitor<dynamic> {
  final Map<String, List<double>> _data;
  dynamic _lastResult;

  FormulaEvaluator(this._data);

  dynamic evaluate(List<Statement> statements) {
    for (final statement in statements) {
      _lastResult = statement.accept(this);
    }
    return _lastResult;
  }

  @override
  dynamic visitBinaryExpression(BinaryExpression node) {
    final left = node.left.accept(this);
    final right = node.right.accept(this);

    // 处理序列数据的比较
    if (left is List<double> && right is List<double>) {
      return _compareSeries(left, right, node.operator);
    }
    // 处理单个值的比较
    else if (left is num && right is num) {
      return _compareValues(left, right, node.operator);
    }
    // 处理逻辑运算
    else if (left is bool && right is bool) {
      return _compareBools(left, right, node.operator);
    }

    throw Exception('无法比较的类型: ${left.runtimeType} 和 ${right.runtimeType}');
  }

  bool _compareSeries(List<double> left, List<double> right, String operator) {
    if (left.length != right.length) {
      throw Exception('序列长度不匹配: ${left.length} != ${right.length}');
    }

    switch (operator) {
      case '>':
        return left.last > right.last;
      case '<':
        return left.last < right.last;
      case '>=':
        return left.last >= right.last;
      case '<=':
        return left.last <= right.last;
      case '==':
        return left.last == right.last;
      case '!=':
        return left.last != right.last;
      default:
        throw Exception('不支持的序列比较运算符: $operator');
    }
  }

  bool _compareValues(num left, num right, String operator) {
    switch (operator) {
      case '>':
        return left > right;
      case '<':
        return left < right;
      case '>=':
        return left >= right;
      case '<=':
        return left <= right;
      case '==':
        return left == right;
      case '!=':
        return left != right;
      default:
        throw Exception('未知的比较运算符: $operator');
    }
  }

  bool _compareBools(bool left, bool right, String operator) {
    switch (operator) {
      case 'AND':
        return left && right;
      case 'OR':
        return left || right;
      default:
        throw Exception('未知的逻辑运算符: $operator');
    }
  }

  @override
  dynamic visitFunctionCall(FunctionCall node) {
    final arguments = node.arguments.map((arg) => arg.accept(this)).toList();

    switch (node.name) {
      case 'MA':
        if (arguments.length != 2) throw Exception('MA函数需要2个参数');
        final series = arguments[0] as List<double>;
        final period = arguments[1] as int;
        return _calculateMA(series, period);

      case 'EMA':
        if (arguments.length != 2) throw Exception('EMA函数需要2个参数');
        final series = arguments[0] as List<double>;
        final period = arguments[1] as int;
        return _calculateEMA(series, period);

      case 'CROSS':
        if (arguments.length != 2) throw Exception('CROSS函数需要2个参数');
        final series1 = arguments[0] as List<double>;
        final series2 = arguments[1] as List<double>;
        return _detectCross(series1, series2);

      // ... 其他函数实现 ...

      default:
        throw Exception('未知的函数: ${node.name}');
    }
  }

  @override
  dynamic visitFieldReference(FieldReference node) {
    return _data[node.name] ?? Exception('未知的字段: ${node.name}');
  }

  @override
  dynamic visitLiteral(Literal node) {
    return node.value;
  }

  @override
  dynamic visitAssignmentStatement(AssignmentStatement node) {
    throw Exception('赋值语句在当前上下文中不支持');
  }

  @override
  dynamic visitExpressionStatement(ExpressionStatement node) {
    return node.expression.accept(this);
  }

  @override
  dynamic visitVariableReference(VariableReference node) {
    throw Exception('变量引用在当前上下文中不支持');
  }

  // ========== 技术指标计算 ==========

  List<double> _calculateMA(List<double> series, int period) {
    if (period <= 0 || period > series.length) {
      throw Exception('无效的周期: $period');
    }

    final result = List<double>.filled(series.length, 0.0);
    for (var i = period - 1; i < series.length; i++) {
      final sum = series.sublist(i - period + 1, i + 1).reduce((a, b) => a + b);
      result[i] = sum / period;
    }
    return result;
  }

  List<double> _calculateEMA(List<double> series, int period) {
    if (period <= 0 || period > series.length) {
      throw Exception('无效的周期: $period');
    }

    final result = List<double>.filled(series.length, 0.0);
    final k = 2.0 / (period + 1);
    result[0] = series[0];

    for (var i = 1; i < series.length; i++) {
      result[i] = series[i] * k + result[i - 1] * (1 - k);
    }

    return result;
  }

  bool _detectCross(List<double> series1, List<double> series2) {
    if (series1.length < 2 || series2.length < 2) return false;
    if (series1.length != series2.length) {
      throw Exception('交叉检测需要相同长度的序列');
    }

    final lastIndex = series1.length - 1;
    return (series1[lastIndex - 1] < series2[lastIndex - 1] &&
            series1[lastIndex] >= series2[lastIndex]) ||
        (series1[lastIndex - 1] > series2[lastIndex - 1] &&
            series1[lastIndex] <= series2[lastIndex]);
  }
}
