// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/formula/function_ema.dart
// Purpose:     ema function
// Author:      songhuabiao
// Created:     2025-07-08 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/formula/expression.dart';
import 'package:irich/formula/formula_ema.dart';

class EmaFunction extends CurveFunction {
  @override
  List<double> evaluate(ConditionContext ctx) {
    return FormulaEma.calculate(ctx.historyKlines, ctx.arguments);
  }
}
