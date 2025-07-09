// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/formula_engine/function_ma.dart
// Purpose:     MACD function
// Author:      songhuabiao
// Created:     2025-07-08 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/service/formula_engine/expression.dart';
import 'package:irich/service/formula_engine/formula/formula_macd.dart';

class MacdFunction extends CurveFunction {
  @override
  List<double> evaluate(ConditionContext ctx) {
    final Map<String, List<double>> result = FormulaMacd.calculate(
      ctx.historyKlines,
      ctx.arguments,
    );
    return result['MACD']!;
  }
}
