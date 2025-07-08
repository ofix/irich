// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/formula/expression_binary.dart
// Purpose:     binary expression
// Author:      songhuabiao
// Created:     2025-07-08 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/formula/expression.dart';

enum Operator {
  div, // + 运算符
  multi, // * 运算符
  add, // + 运算符
  sub, // - 运算符
  greater, // > 运算符
  greaterEqual, // >= 运算符
  smaller, // < 运算符
  smallerEqual, // <= 运算符
  equal, // == 运算符
  notEqual, // != 运算符
}

class BinaryExpression extends Expression {
  ArithmeticExpression leftExpr;
  ArithmeticExpression rightExpr;
  Operator operator;
  BinaryExpression({required this.leftExpr, required this.rightExpr, required this.operator});
  @override
  dynamic evaluate(ConditionContext ctx) {
    switch (operator) {
      case Operator.add:
        return leftExpr.evaluate(ctx) + rightExpr.evaluate(ctx);
      case Operator.sub:
        return leftExpr.evaluate(ctx) - rightExpr.evaluate(ctx);
      case Operator.multi:
        return leftExpr.evaluate(ctx) * rightExpr.evaluate(ctx);
      case Operator.div:
        return leftExpr.evaluate(ctx) / rightExpr.evaluate(ctx);
      case Operator.greater:
        return leftExpr.evaluate(ctx) > rightExpr.evaluate(ctx);
      case Operator.greaterEqual:
        return leftExpr.evaluate(ctx) >= rightExpr.evaluate(ctx);
      case Operator.smaller:
        return leftExpr.evaluate(ctx) < rightExpr.evaluate(ctx);
      case Operator.smallerEqual:
        return leftExpr.evaluate(ctx) <= rightExpr.evaluate(ctx);
      case Operator.equal:
        return leftExpr.evaluate(ctx) == rightExpr.evaluate(ctx);
      case Operator.notEqual:
        return leftExpr.evaluate(ctx) != rightExpr.evaluate(ctx);
    }
  }
}
