// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/formula_engine/formula/formula_ema.dart
// Purpose:     day kline ema formula
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/service/formula_engine/formula/formula.dart';
import 'package:irich/global/stock.dart';

class FormulaEma extends Formula {
  FormulaEma() : super(FormulaType.ema);

  /// 计算EMA指标
  /// [klines] K线数据列表
  /// [period] EMA周期
  /// 返回EMA值列表
  static List<double> calc(List<UiKline> klines, int period) {
    final emaPrices = <double>[];
    if (klines.isEmpty || period <= 0) return emaPrices;

    // 初始化EMA为第一个收盘价
    double emaPrice = klines.first.priceClose;
    final multiplier = 2.0 / (period + 1); // 计算平滑因子
    emaPrices.add(emaPrice);

    for (int i = 1; i < klines.length; i++) {
      // 计算EMA: (当前收盘价 - 前一日EMA) * 平滑因子 + 前一日EMA
      emaPrice = (klines[i].priceClose - emaPrice) * multiplier + emaPrice;
      emaPrices.add(emaPrice);
    }

    return emaPrices;
  }

  static dynamic calculate(List<UiKline> klines, Map<String, dynamic> params) {
    final period = params['Period'] ?? 20; // 默认参数
    return FormulaEma.calc(klines, period);
  }
}
