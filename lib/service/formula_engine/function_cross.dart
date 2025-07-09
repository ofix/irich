// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/formula_engine/function_cross.dart
// Purpose:     cross function
// Author:      songhuabiao
// Created:     2025-07-08 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/service/formula_engine/expression.dart';

class CrossFunction implements Expression {
  final CurveFunction left;
  final CurveFunction right;
  CrossFunction({required this.left, required this.right});
  @override
  bool evaluate(ConditionContext ctx) {
    final List<double> curve1 = left.evaluate(ctx);
    final List<double> curve2 = right.evaluate(ctx);
    // 前一天曲线的值
    double curve1Prev = curve1[curve1.length - 2];
    double curve2Prev = curve2[curve2.length - 2];
    // 今天曲线的值
    double curve1Cur = curve1.last;
    double curve2Cur = curve2.last;
    // 上穿条件：前一天 curve1≤ curve2，且当前 curve1 > curve2
    final crossSignal = (curve1Prev <= curve2Prev) & (curve1Cur > curve2Cur);
    return crossSignal;
  }
}
