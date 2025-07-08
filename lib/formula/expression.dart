// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/formula/expression.dart
// Purpose:     expression classes
// Author:      songhuabiao
// Created:     2025-07-08 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

// 条件表达式上下文环境
import 'package:irich/global/stock.dart';

class ConditionContext {
  Share share; // 当前股票
  List<UiKline> historyKlines; // 历史K线
  Map<String, dynamic> arguments; // 表达式参数，函数表达式要用
  ConditionContext({required this.share, required this.arguments, required this.historyKlines});
}

abstract class Expression {
  dynamic evaluate(ConditionContext ctx);
}

abstract class ArithmeticExpression extends Expression {
  @override
  double evaluate(ConditionContext ctx);
}

abstract class CurveFunction extends Expression {
  @override
  List<double> evaluate(ConditionContext ctx);
}
