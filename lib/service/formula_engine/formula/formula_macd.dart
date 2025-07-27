// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/formula_engine/formula/formula_macd.dart
// Purpose:     day kline macd formula
// Author:      songhuabiao
// Created:     2025-06-05 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:math';

import 'package:irich/service/formula_engine/formula/formula.dart';
import 'package:irich/service/formula_engine/formula/formula_ema.dart';
import 'package:irich/global/stock.dart';

/// 股票 MACD 技术指标
class FormulaMacd implements Formula {
  @override
  FormulaType get type => FormulaType.macd;
  // 原理
  // MACD（Moving Average Convergence Divergence）即指数平滑异同移动平均线，由Gerald Appel于1970年代提出。它通过计算不同周期的指数移动平均线（EMA）之间的差异来判断趋势强度和方向。

  // 公式
  // 计算12日EMA（快速线）：EMA12
  // 计算26日EMA（慢速线）：EMA26
  // DIF = EMA12 - EMA26
  // DEA = DIF的9日EMA（信号线）
  // MACD柱 = (DIF - DEA) × 2

  final List<UiKline> klines;
  final int fastPeriod;
  final int slowPeriod;
  final int signalPeriod;

  /// 计算EMA指标
  /// [klines] K线数据列表
  /// [fastPeriod] EMA快周期
  /// [slowPeriod] EMA慢周期
  /// [signalPeriod] 信号周期
  /// 返回MACD列表
  FormulaMacd({
    required this.klines,
    this.fastPeriod = 12,
    this.slowPeriod = 26,
    this.signalPeriod = 9,
  });

  Map<String, List<double>> calc() {
    final emaFast = FormulaEma.calc(klines, fastPeriod);
    final emaSlow = FormulaEma.calc(klines, slowPeriod);

    final dif = List<double>.generate(klines.length, (i) {
      if (i < slowPeriod - 1) return 0;
      return emaFast[i] - emaSlow[i];
    });

    final dea = calcEma(dif, signalPeriod);

    final macd = List<double>.generate(klines.length, (i) {
      if (i < slowPeriod + signalPeriod - 2) return 0;
      return (dif[i] - dea[i]) * 2;
    });

    return {'DIF': dif, 'DEA': dea, 'MACD': macd};
  }

  static List<double> calcEma(List<double> prices, int period) {
    final ema = List<double>.filled(prices.length, 0);

    // 防止K线数量小于period，内存下标越界
    final safePeriod = min(period, prices.length - 1);
    final multiplier = 2 / (safePeriod + 1);

    // 第一个EMA是简单移动平均
    double sum = 0;
    for (int i = 0; i < safePeriod; i++) {
      sum += prices[i];
      ema[i] = i == safePeriod - 1 ? sum / safePeriod : 0;
    }

    // 计算后续EMA
    for (int i = safePeriod; i < prices.length; i++) {
      final iPrev = i - 1 < 0 ? 0 : i - 1;
      ema[i] = (prices[i] - ema[iPrev]) * multiplier + ema[iPrev];
    }

    return ema;
  }

  static Map<String, List<double>> calculate(List<UiKline> klines, Map<String, dynamic> params) {
    final fastPeriod = params['FastPeriod'] ?? 12;
    final slowPeriod = params['SlowPeriod'] ?? 26;
    final signalPeriod = params['SignalPeriod'] ?? 9;

    return FormulaMacd(
      klines: klines,
      fastPeriod: fastPeriod,
      slowPeriod: slowPeriod,
      signalPeriod: signalPeriod,
    ).calc();
  }
}
