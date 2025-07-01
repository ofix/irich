// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/backtest_service.dart
// Purpose:     backtesting service
// Author:      songhuabiao
// Created:     2025-07-01 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:math';
import 'package:irich/global/backtest.dart';

class BacktestService {
  // 运行回测
  Future<BacktestResult> runBacktest(
    List<Factor> factors,
    Map<String, List<MarketData>> marketDataMap,
    double initialCapital,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // 按日期排序因子
    factors.sort((a, b) => a.date.compareTo(b.date));

    // 准备回测数据
    double currentCapital = initialCapital;
    double maxCapital = initialCapital;
    double maxDrawdown = 0;
    int totalTrades = 0;
    int winningTrades = 0;
    final trades = <TradeRecord>[];
    final portfolioValues = <PortfolioValuePoint>[];

    // 持仓信息
    final holdings = <String, double>{}; // 股票代码 -> 持有数量

    // 按日期循环执行回测
    final tradingDates = _getTradingDates(marketDataMap);
    final filteredDates =
        tradingDates.where((date) => date.isAfter(startDate) && date.isBefore(endDate)).toList();

    // 记录每日组合价值
    for (final date in filteredDates) {
      // 检查是否有新的因子数据可用，决定是否调仓
      final latestFactors = factors.where((f) => f.date.isBefore(date)).toList();

      if (latestFactors.isNotEmpty) {
        // 获取最新的因子数据
        final latestFactorDate = latestFactors
            .map((f) => f.date)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        final latestFactorData = latestFactors.where((f) => f.date == latestFactorDate).toList();

        // 基于因子数据生成交易信号并执行交易
        final signals = _generateSignals(latestFactorData);
        await _executeTrades(signals, date, marketDataMap, holdings, currentCapital);
      }

      // 计算当日组合价值
      final portfolioValue =
          _calculatePortfolioValue(date, marketDataMap, holdings) + currentCapital;
      portfolioValues.add(PortfolioValuePoint(date: date, value: portfolioValue));

      // 更新最大回撤
      maxCapital = max(maxCapital, portfolioValue);
      final drawdown = 1 - (portfolioValue / maxCapital);
      maxDrawdown = max(maxDrawdown, drawdown);
    }

    // 计算回测结果
    final finalCapital = portfolioValues.isNotEmpty ? portfolioValues.last.value : initialCapital;

    final totalReturn = (finalCapital - initialCapital) / initialCapital;
    final days = endDate.difference(startDate).inDays;
    final annualizedReturn = pow(1 + totalReturn, 365 / days) - 1;

    // 计算夏普比率 (简化：假设无风险收益率为0)
    final dailyReturns = _calculateDailyReturns(portfolioValues);
    final avgDailyReturn =
        dailyReturns.isNotEmpty ? dailyReturns.reduce((a, b) => a + b) / dailyReturns.length : 0;

    final stdDevDailyReturn = _calculateStandardDeviation(dailyReturns);
    final sharpeRatio =
        stdDevDailyReturn != 0 ? (avgDailyReturn / stdDevDailyReturn) * sqrt(252) : 0;

    // 计算胜率
    final winRate = trades.isNotEmpty ? winningTrades / trades.length : 0;

    return BacktestResult(
      initialCapital: initialCapital,
      finalCapital: finalCapital,
      totalReturn: totalReturn,
      annualizedReturn: annualizedReturn.toDouble(),
      maxDrawdown: maxDrawdown,
      sharpeRatio: sharpeRatio.toDouble(),
      winRate: winRate.toDouble(),
      totalTrades: totalTrades,
      trades: trades,
      portfolioValues: portfolioValues,
    );
  }

  // 获取所有交易日期
  List<DateTime> _getTradingDates(Map<String, List<MarketData>> marketDataMap) {
    final allDates = <DateTime>{};

    for (final stockCode in marketDataMap.keys) {
      final dates = marketDataMap[stockCode]!.map((data) => data.date).toList();
      allDates.addAll(dates);
    }

    return allDates.toList()..sort();
  }

  // 生成交易信号
  List<Map<String, dynamic>> _generateSignals(List<Factor> factors) {
    // 简化示例：基于综合得分生成买卖信号
    final signals = <Map<String, dynamic>>[];

    // 按综合得分排序
    factors.sort((a, b) => b.compositeScore.compareTo(a.compositeScore));

    // 选择前10%作为买入信号，后10%作为卖出信号
    final topCount = (factors.length * 0.1).ceil();
    final bottomCount = (factors.length * 0.1).ceil();

    // 生成买入信号
    for (int i = 0; i < topCount && i < factors.length; i++) {
      signals.add({
        'stockCode': factors[i].stockCode,
        'action': 'buy',
        'weight': 1.0 / topCount, // 平均分配资金
      });
    }

    // 生成卖出信号
    for (int i = 0; i < bottomCount && i < factors.length; i++) {
      signals.add({
        'stockCode': factors[factors.length - 1 - i].stockCode,
        'action': 'sell',
        'weight': 1.0, // 全部卖出
      });
    }

    return signals;
  }

  // 执行交易
  Future<void> _executeTrades(
    List<Map<String, dynamic>> signals,
    DateTime date,
    Map<String, List<MarketData>> marketDataMap,
    Map<String, double> holdings,
    double currentCapital,
  ) async {
    // 先处理卖出信号
    for (final signal in signals.where((s) => s['action'] == 'sell')) {
      final stockCode = signal['stockCode'] as String;

      if (holdings.containsKey(stockCode)) {
        final quantity = holdings[stockCode]!;

        // 找到当日的市场数据
        final marketData = marketDataMap[stockCode]?.firstWhere(
          (data) => data.date == date,
          orElse:
              () => MarketData(
                stockCode: stockCode,
                date: date,
                open: 0,
                high: 0,
                low: 0,
                close: 0,
                volume: 0,
              ),
        );

        if (marketData != null && marketData.close > 0) {
          // 计算卖出获得的资金
          final proceeds = quantity * marketData.close;
          currentCapital += proceeds;

          // 移除持仓
          holdings.remove(stockCode);
        }
      }
    }

    // 再处理买入信号
    final totalBuyWeight = signals
        .where((s) => s['action'] == 'buy')
        .fold(0.0, (sum, signal) => sum + (signal['weight'] as double));

    for (final signal in signals.where((s) => s['action'] == 'buy')) {
      final stockCode = signal['stockCode'] as String;
      final weight = (signal['weight'] as double) / totalBuyWeight;

      // 找到当日的市场数据
      final marketData = marketDataMap[stockCode]?.firstWhere(
        (data) => data.date == date,
        orElse:
            () => MarketData(
              stockCode: stockCode,
              date: date,
              open: 0,
              high: 0,
              low: 0,
              close: 0,
              volume: 0,
            ),
      );

      if (marketData != null && marketData.close > 0) {
        // 计算可购买的数量
        final amountToInvest = currentCapital * weight;
        final quantity = amountToInvest / marketData.close;

        // 更新持仓和资金
        holdings[stockCode] = quantity;
        currentCapital -= amountToInvest;
      }
    }
  }

  // 计算组合价值
  double _calculatePortfolioValue(
    DateTime date,
    Map<String, List<MarketData>> marketDataMap,
    Map<String, double> holdings,
  ) {
    double value = 0;

    for (final stockCode in holdings.keys) {
      final quantity = holdings[stockCode]!;

      // 找到当日的市场数据
      final marketData = marketDataMap[stockCode]?.firstWhere(
        (data) => data.date == date,
        orElse:
            () => MarketData(
              stockCode: stockCode,
              date: date,
              open: 0,
              high: 0,
              low: 0,
              close: 0,
              volume: 0,
            ),
      );

      if (marketData != null) {
        value += quantity * marketData.close;
      }
    }

    return value;
  }

  // 计算每日收益率
  List<double> _calculateDailyReturns(List<PortfolioValuePoint> portfolioValues) {
    final returns = <double>[];

    for (int i = 1; i < portfolioValues.length; i++) {
      final prevValue = portfolioValues[i - 1].value;
      final currentValue = portfolioValues[i].value;

      if (prevValue > 0) {
        returns.add((currentValue / prevValue) - 1);
      }
    }

    return returns;
  }

  // 计算标准差
  double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2)).toList();
    final variance = squaredDiffs.reduce((a, b) => a + b) / values.length;

    return sqrt(variance);
  }
}
