// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/formula/expression_engine.dart
// Purpose:     expression engine
// Author:      songhuabiao
// Created:     2025-07-08 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/formula/expression.dart';
import 'package:irich/global/stock.dart';

// 表达式执行引擎
class ExpressionEngine {
  late ConditionContext ctx;
  late List<Expression> expressions; // 表达式列表
  ExpressionEngine();
  List<Share> filter() {
    List<Share> originShares = []; // 原始列表
    List<Share> filteredShares = []; // 过滤后的列表
    for (final expression in expressions) {
      filteredShares = [];
      for (final share in originShares) {
        ctx.share = share;
        bool match = expression.evaluate(ctx);
        if (match) {
          // 满足过滤条件
          filteredShares.add(share);
        }
      }
      originShares = filteredShares;
    }
    return filteredShares;
  }
}
