// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/formula_engine/formula/formula_ema.dart
// Purpose:     day kline ema formula
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:math';

import 'package:irich/service/formula_engine/formula/formula.dart';
import 'package:irich/global/stock.dart';

class FormulaBoll implements Formula {
  // 原理
  // 布林线（Bollinger Bands）由John Bollinger在1980年代提出，由三条轨道线组成：中轨（移动平均线）、上轨和下轨。上下轨是基于标准差计算的，能够反映价格波动的区间。

  // 公式
  // 中轨（MB）= N日移动平均线（MA）
  // 上轨（UP）= MB + k × N日标准差
  // 下轨（DN）= MB - k × N日标准差
  // 通常N=20，k=2
  @override
  FormulaType get type => FormulaType.boll;

  final List<UiKline> klines;
  final int period;
  final double multiplier;
  FormulaBoll({required this.klines, this.period = 20, this.multiplier = 2.0}) : super();

  Map<String, List<double>> calc() {
    final middleBand = _calculateSMA(klines, period);
    final upperBand = List<double>.filled(klines.length, 0);
    final lowerBand = List<double>.filled(klines.length, 0);

    for (int i = period - 1; i < klines.length; i++) {
      final subList = klines.sublist(i - period + 1, i + 1);
      final stdDev = _calculateStdDev(subList, middleBand[i]);

      upperBand[i] = middleBand[i] + multiplier * stdDev;
      lowerBand[i] = middleBand[i] - multiplier * stdDev;
    }

    return {'upper': upperBand, 'middle': middleBand, 'lower': lowerBand};
  }

  List<double> _calculateSMA(List<UiKline> klines, int period) {
    final sma = List<double>.filled(klines.length, 0);

    for (int i = period - 1; i < klines.length; i++) {
      double sum = 0;
      for (int j = i - period + 1; j <= i; j++) {
        sum += klines[j].priceClose;
      }
      sma[i] = sum / period;
    }

    return sma;
  }

  double _calculateStdDev(List<UiKline> klines, double mean) {
    double sum = 0;
    for (final kline in klines) {
      sum += (kline.priceClose - mean) * (kline.priceClose - mean);
    }
    return sqrt(sum / klines.length);
  }

  static Map<String, List<double>> calculate(List<UiKline> klines, Map<String, dynamic> params) {
    final period = params['Period'] ?? 20; // 默认参数
    final multiplier = params['multiplier'] ?? 2.0;
    return FormulaBoll(klines: klines, period: period, multiplier: multiplier).calc();
  }
}
