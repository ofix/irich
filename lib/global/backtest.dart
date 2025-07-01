// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/global/backtest.dart
// Purpose:     classes for backtest
// Author:      songhuabiao
// Created:     2025-07-01 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

class Factor {
  final String stockCode;
  final DateTime date;
  final double roe; // 净资产收益率
  final double profitGrowth; // 净利润增长率
  final double revenueGrowth; // 营业收入增长率
  final double debtRatio; // 资产负债率
  final double grossMargin; // 毛利率
  final double marketCap; // 市值

  Factor({
    required this.stockCode,
    required this.date,
    required this.roe,
    required this.profitGrowth,
    required this.revenueGrowth,
    required this.debtRatio,
    required this.grossMargin,
    required this.marketCap,
  });

  // 计算综合得分 (简化示例)
  double get compositeScore {
    // 这里可以根据不同因子的权重计算综合得分
    // 实际应用中可能需要更复杂的模型
    return (roe * 0.3) +
        (profitGrowth * 0.25) +
        (revenueGrowth * 0.2) +
        ((1 - debtRatio) * 0.15) +
        (grossMargin * 0.1);
  }
}

class FinancialData {
  final String stockCode;
  final DateTime reportDate;
  final double totalAssets;
  final double totalLiabilities;
  final double shareholdersEquity;
  final double netProfit;
  final double operatingRevenue;
  final double operatingProfit;
  final double cashFlowFromOperations;

  FinancialData({
    required this.stockCode,
    required this.reportDate,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.shareholdersEquity,
    required this.netProfit,
    required this.operatingRevenue,
    required this.operatingProfit,
    required this.cashFlowFromOperations,
  });

  // 从数据库记录创建财务数据对象
  factory FinancialData.fromMap(Map<String, dynamic> map) {
    return FinancialData(
      stockCode: map['stock_code'],
      reportDate: DateTime.parse(map['report_date']),
      totalAssets: map['total_assets']?.toDouble() ?? 0.0,
      totalLiabilities: map['total_liabilities']?.toDouble() ?? 0.0,
      shareholdersEquity: map['shareholders_equity']?.toDouble() ?? 0.0,
      netProfit: map['net_profit']?.toDouble() ?? 0.0,
      operatingRevenue: map['operating_revenue']?.toDouble() ?? 0.0,
      operatingProfit: map['operating_profit']?.toDouble() ?? 0.0,
      cashFlowFromOperations: map['cash_flow_from_operations']?.toDouble() ?? 0.0,
    );
  }

  // 计算ROE (净资产收益率)
  double get roe => shareholdersEquity > 0 ? netProfit / shareholdersEquity : 0;

  // 计算资产负债率
  double get debtToAssetRatio => totalAssets > 0 ? totalLiabilities / totalAssets : 0;

  // 计算毛利率
  double get grossProfitMargin =>
      operatingRevenue > 0 ? (operatingRevenue - operatingProfit) / operatingRevenue : 0;
}

class BacktestResult {
  final double initialCapital;
  final double finalCapital;
  final double totalReturn;
  final double annualizedReturn;
  final double maxDrawdown;
  final double sharpeRatio;
  final double winRate;
  final int totalTrades;
  final List<TradeRecord> trades;
  final List<PortfolioValuePoint> portfolioValues;

  BacktestResult({
    required this.initialCapital,
    required this.finalCapital,
    required this.totalReturn,
    required this.annualizedReturn,
    required this.maxDrawdown,
    required this.sharpeRatio,
    required this.winRate,
    required this.totalTrades,
    required this.trades,
    required this.portfolioValues,
  });
}

class TradeRecord {
  final String stockCode;
  final DateTime buyDate;
  final double buyPrice;
  final DateTime sellDate;
  final double sellPrice;
  final double profit;
  final bool isWin;

  TradeRecord({
    required this.stockCode,
    required this.buyDate,
    required this.buyPrice,
    required this.sellDate,
    required this.sellPrice,
    required this.profit,
    required this.isWin,
  });
}

class PortfolioValuePoint {
  final DateTime date;
  final double value;

  PortfolioValuePoint({required this.date, required this.value});
}

class MarketData {
  final String stockCode;
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  MarketData({
    required this.stockCode,
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  // 从数据库记录创建市场数据对象
  factory MarketData.fromMap(Map<String, dynamic> map) {
    return MarketData(
      stockCode: map['stock_code'],
      date: DateTime.parse(map['trade_date']),
      open: map['open_price']?.toDouble() ?? 0.0,
      high: map['high_price']?.toDouble() ?? 0.0,
      low: map['low_price']?.toDouble() ?? 0.0,
      close: map['close_price']?.toDouble() ?? 0.0,
      volume: map['volume']?.toDouble() ?? 0.0,
    );
  }
}

class Stock {
  final String code;
  final String name;
  final String industry;

  Stock({required this.code, required this.name, required this.industry});

  // 从数据库记录创建股票对象
  factory Stock.fromMap(Map<String, dynamic> map) {
    return Stock(code: map['stock_code'], name: map['stock_name'], industry: map['industry']);
  }

  @override
  String toString() {
    return '$name ($code)';
  }
}
