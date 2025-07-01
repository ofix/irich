// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/factor_service.dart
// Purpose:     factor service
// Author:      songhuabiao
// Created:     2025-07-01 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:math';
import 'package:irich/global/backtest.dart';

class FactorService {
  // 计算单只股票的因子数据
  Future<List<Factor>> calculateFactors(
    String stockCode,
    List<FinancialData> financialData,
    List<MarketData> marketData,
  ) async {
    // 按日期排序财务数据
    financialData.sort((a, b) => a.reportDate.compareTo(b.reportDate));

    // 按日期排序市场数据
    marketData.sort((a, b) => a.date.compareTo(b.date));

    // 用于存储因子结果
    final factors = <Factor>[];

    // 计算每个报告期的因子
    for (int i = 0; i < financialData.length; i++) {
      final currentData = financialData[i];

      // 计算同比增长率
      double profitGrowth = 0.0;
      double revenueGrowth = 0.0;

      if (i > 0) {
        final previousData = financialData[i - 1];

        // 净利润同比增长率
        if (previousData.netProfit != 0) {
          profitGrowth = (currentData.netProfit - previousData.netProfit) / previousData.netProfit;
        }

        // 营业收入同比增长率
        if (previousData.operatingRevenue != 0) {
          revenueGrowth =
              (currentData.operatingRevenue - previousData.operatingRevenue) /
              previousData.operatingRevenue;
        }
      }

      // 找到对应报告期后的最近市场数据点，用于计算市值
      final marketDataPoint = _findClosestMarketDataAfterReport(currentData.reportDate, marketData);

      // 计算市值 (简化：假设流通股本为1亿)
      double marketCap = marketDataPoint != null ? marketDataPoint.close * 100000000 : 0;

      // 创建因子对象
      final factor = Factor(
        stockCode: stockCode,
        date: currentData.reportDate,
        roe: currentData.roe,
        profitGrowth: profitGrowth,
        revenueGrowth: revenueGrowth,
        debtRatio: currentData.debtToAssetRatio,
        grossMargin: currentData.grossProfitMargin,
        marketCap: marketCap,
      );

      factors.add(factor);
    }

    return factors;
  }

  // 找到报告期后最近的市场数据点
  MarketData? _findClosestMarketDataAfterReport(DateTime reportDate, List<MarketData> marketData) {
    for (final data in marketData) {
      if (data.date.isAfter(reportDate)) {
        return data;
      }
    }
    return null;
  }

  // 标准化因子数据
  List<Factor> normalizeFactors(List<Factor> factors) {
    if (factors.isEmpty) return [];

    // 提取各因子的值用于计算统计量
    final roeValues = factors.map((f) => f.roe).toList();
    final profitGrowthValues = factors.map((f) => f.profitGrowth).toList();
    final revenueGrowthValues = factors.map((f) => f.revenueGrowth).toList();
    final debtRatioValues = factors.map((f) => f.debtRatio).toList();
    final grossMarginValues = factors.map((f) => f.grossMargin).toList();

    // 计算各因子的均值和标准差
    final roeStats = _calculateStats(roeValues);
    final profitGrowthStats = _calculateStats(profitGrowthValues);
    final revenueGrowthStats = _calculateStats(revenueGrowthValues);
    final debtRatioStats = _calculateStats(debtRatioValues);
    final grossMarginStats = _calculateStats(grossMarginValues);

    // 标准化每个因子
    return factors.map((factor) {
      double normalizedRoe = _normalizeValue(factor.roe, roeStats);
      double normalizedProfitGrowth = _normalizeValue(factor.profitGrowth, profitGrowthStats);
      double normalizedRevenueGrowth = _normalizeValue(factor.revenueGrowth, revenueGrowthStats);
      double normalizedDebtRatio = _normalizeValue(factor.debtRatio, debtRatioStats);
      double normalizedGrossMargin = _normalizeValue(factor.grossMargin, grossMarginStats);

      return Factor(
        stockCode: factor.stockCode,
        date: factor.date,
        roe: normalizedRoe,
        profitGrowth: normalizedProfitGrowth,
        revenueGrowth: normalizedRevenueGrowth,
        debtRatio: normalizedDebtRatio,
        grossMargin: normalizedGrossMargin,
        marketCap: factor.marketCap,
      );
    }).toList();
  }

  // 计算统计量 (均值和标准差)
  Map<String, double> _calculateStats(List<double> values) {
    // 过滤无效值
    final validValues = values.where((v) => !v.isNaN && !v.isInfinite).toList();

    if (validValues.isEmpty) {
      return {'mean': 0, 'stdDev': 1};
    }

    // 计算均值
    final sum = validValues.reduce((a, b) => a + b);
    final mean = sum / validValues.length;

    // 计算标准差
    final squaredDiffs = validValues.map((v) => pow(v - mean, 2)).toList();
    final variance = squaredDiffs.reduce((a, b) => a + b) / validValues.length;
    final stdDev = sqrt(variance);

    // 防止除以零
    if (stdDev == 0) {
      return {'mean': mean, 'stdDev': 1};
    }

    return {'mean': mean, 'stdDev': stdDev};
  }

  // 标准化单个值
  double _normalizeValue(double value, Map<String, double> stats) {
    if (value.isNaN || value.isInfinite) return 0;
    return (value - stats['mean']!) / stats['stdDev']!;
  }
}
