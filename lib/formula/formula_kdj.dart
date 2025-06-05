// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/formula/formula_kdj.dart
// Purpose:     day kline kdj formula
// Author:      songhuabiao
// Created:     2025-06-05 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/formula/formula.dart';
import 'package:irich/global/stock.dart';

/// 股票 KDJ 指标
class FormulaKdj extends Formula {
  // 原理
  // KDJ指标（随机指标）由George Lane提出，通过比较近期收盘价与价格区间的关系，反映价格趋势的强弱和超买超卖状态。

  // 公式
  // 计算N日内的最低价（L）和最高价（H）
  // 计算未成熟随机值RSV = (收盘价 - L) / (H - L) × 100
  // K值 = 前一日K值 × 2/3 + 当日RSV × 1/3
  // D值 = 前一日D值 × 2/3 + 当日K值 × 1/3
  // J值 = 3 × K值 - 2 × D值
  // 通常N=9
  final List<UiKline> klines;
  final int period;

  /// 计算EMA指标
  /// [klines] K线数据列表
  /// [period] KDJ周期
  /// 返回KDJ列表
  FormulaKdj({required this.klines, this.period = 9}) : super(FormulaType.kdj);

  Map<String, List<double>> calc() {
    final k = List<double>.filled(klines.length, 50);
    final d = List<double>.filled(klines.length, 50);
    final j = List<double>.filled(klines.length, 50);

    for (int i = period - 1; i < klines.length; i++) {
      final subList = klines.sublist(i - period + 1, i + 1);
      // 修正1：正确获取最高价和最低价
      double periodMaxPrice = subList[0].priceMax;
      double periodMinPrice = subList[0].priceMin;

      for (final kline in subList) {
        if (kline.priceMax > periodMaxPrice) periodMaxPrice = kline.priceMax;
        if (kline.priceMin < periodMinPrice) periodMinPrice = kline.priceMin;
      }

      // 修正2：防止除以零的情况
      double rsv;
      if (periodMaxPrice == periodMinPrice) {
        rsv = 50; // 当最高价等于最低价时，设为中间值
      } else {
        rsv = (klines[i].priceClose - periodMinPrice) / (periodMaxPrice - periodMinPrice) * 100;
      }

      k[i] = i == period - 1 ? 50 * 2 / 3 + rsv * 1 / 3 : k[i - 1] * 2 / 3 + rsv * 1 / 3;
      d[i] = i == period - 1 ? 50 * 2 / 3 + k[i] * 1 / 3 : d[i - 1] * 2 / 3 + k[i] * 1 / 3;
      j[i] = 3 * k[i] - 2 * d[i];
    }

    return {'k': k, 'd': d, 'j': j};
  }

  static Map<String, List<double>> calculate(List<UiKline> klines, Map<String, dynamic> params) {
    final period = params['Period'] ?? 9; // 默认参数
    return FormulaKdj(klines: klines, period: period).calc();
  }
}
