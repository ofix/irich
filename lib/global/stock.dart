// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/global/stock.dart
// Purpose:     global classes and enumes definition
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';

enum Market {
  shangHai(1, '上海A股'), // 沪市
  shenZhen(2, '深圳A股'), // 深市
  chuangYeBan(3, '创业板'), // 创业板
  keChuangBan(4, '科创板'), // 科创板
  beiJiaoSuo(5, '北交所'); // 北交所

  final int market;
  final String name;
  const Market(this.market, this.name);
  static const Map<int, String> marketMap = {1: '上海A股', 2: '深圳A股', 3: '创业板', 4: '科创板', 5: '北交所'};
  static String getMarketName(int market) {
    return marketMap[market] ?? '未知市场';
  }

  // 数字转枚举的工厂方法
  static Market fromVal(int value) {
    switch (value) {
      case 1:
        return Market.shangHai;
      case 2:
        return Market.shenZhen;
      case 3:
        return Market.chuangYeBan;
      case 4:
        return Market.keChuangBan;
      case 5:
        return Market.beiJiaoSuo;
      default:
        throw ArgumentError('Invalid market code: $value');
    }
  }
}

class ShareIndustry {
  final int source; // 行业分类来源（申万/中信）
  final int level; // 行业分类等级（1, 2, 3）
  final String name; // 行业分类名称

  // 构造函数
  ShareIndustry({required this.source, required this.level, required this.name});

  // 可选：添加工厂构造函数（如从 JSON 解析）
  // factory ShareIndustry.fromJson(Map<String, dynamic> json) {
  //   return ShareIndustry(
  //     source: json['source'] as int,
  //     level: json['level'] as int,
  //     name: json['name'] as String,
  //   );
  // }

  // // 可选：转换为 JSON
  // Map<String, dynamic> toJson() => {
  //   'source': source,
  //   'level': level,
  //   'name': name,
  // };
}

enum KlineType {
  minute, // 分时图
  fiveDay, // 近5日分时图
  day, // 日K线
  week, // 周K线
  month, // 月K线
  quarter, // 季度K线
  year; // 年K线

  bool get isMinuteType => this == KlineType.minute || this == KlineType.fiveDay;
}

enum DataProvider {
  financeBaidu, // 百度财经
  eastMoney, // 东方财富
  hexun, // 和讯网
}

enum ShareCategoryType {
  concept(1), // 概念板块
  industry(2), // 行业板块
  province(4); // 区域板块

  final int type;
  const ShareCategoryType(this.type);
  static const Map<int, String> typeMap = {1: '概念板块', 2: '行业板块', 4: '区域板块'};
  static String getTypeName(int type) {
    return typeMap[type] ?? '未知类型';
  }

  static int getTypeValue(String typeName) {
    return typeMap.entries
        .firstWhere((entry) => entry.value == typeName, orElse: () => const MapEntry(0, '未知类型'))
        .key;
  }
}

class ShareConcept {
  String name;
  List<Share> shares;

  ShareConcept(this.name, this.shares);
}

class ShareBonus {
  int value; // 分红金额
  String plan; // 分红方案
  String date; // 分红日期
  // 构造函数
  // 可选：添加工厂构造函数（如从 JSON 解析）
  // 可选：转换为 JSON
  // Map<String, dynamic> toJson() => {
  //   'value': value,
  //   'plan': plan,
  //   'date': date,
  // };
  ShareBonus(this.value, this.plan, this.date);
}

class ShareCapital {
  int total; // 总市值
  int trade; // 流通股本
  String date; // 股本变化时间
  // 构造函数
  // 可选：添加工厂构造函数（如从 JSON 解析）
  // 可选：转换为 JSON
  // Map<String, dynamic> toJson() => {
  //   'total': total,
  //   'trade': trade,
  //   'date': date,
  // };
  ShareCapital(this.total, this.trade, this.date);
}

class ShareHolder {
  int count; // 股东人数
  String date; // 股东人数公告日期
  ShareHolder(this.count, this.date);
}

class Top10ShareHolder {
  String name; // 股东名称
  int shareQuantity; // 持股数量

  Top10ShareHolder(this.name, this.shareQuantity);
}

class ShareInvestmentFund {
  String name; // 投资机构名称
  int shareQuantity; // 持股数量

  ShareInvestmentFund(this.name, this.shareQuantity);
}

class ShareBasicInfo {
  List<ShareBonus> historyBonus; // 历史分红方案
  int totalBonus; // 上市总分红金额
  int totalFund; // 上市总融资金额
  List<ShareCapital> capitalChangeHistory; // 股本变化历史
  List<ShareHolder> holderChangeHistory; // 股东人数变化历史
  List<ShareInvestmentFund> shareInvestmentFunds; // 投资机构
  List<Top10ShareHolder> top10ShareHolders; // 10大股东
  List<Top10ShareHolder> top10TradeShareHolders; // 10大流通股东

  ShareBasicInfo({
    required this.historyBonus,
    required this.totalBonus,
    required this.totalFund,
    required this.capitalChangeHistory,
    required this.holderChangeHistory,
    required this.shareInvestmentFunds,
    required this.top10ShareHolders,
    required this.top10TradeShareHolders,
  });
}

class ShareBriefInfo {
  String companyName; // 公司名称
  String oldNames; // 公司曾用名
  String companyWebsite; // 公司网址
  String registerAddress; // 注册地址
  int staffNum; // 雇员人数
  double registerCapital; // 注册资本
  String lawOffice; // 律师事务所
  String accountingOffice; // 会计事务所
  String ceo; // 公司董事长
  String boardSecretary; // 董秘
  String officeAddress; // 办公地址
  String companyProfile; // 公司简介

  ShareBriefInfo({
    required this.companyName,
    required this.oldNames,
    required this.companyWebsite,
    required this.registerAddress,
    required this.staffNum,
    required this.registerCapital,
    required this.lawOffice,
    required this.accountingOffice,
    required this.ceo,
    required this.boardSecretary,
    required this.officeAddress,
    required this.companyProfile,
  });

  ShareBriefInfo copyWith({
    String? companyName,
    String? oldNames,
    String? companyWebsite,
    String? registerAddress,
    int? staffNum,
    double? registerCapital,
    String? lawOffice,
    String? accountingOffice,
    String? ceo,
    String? boardSecretary,
    String? officeAddress,
    String? companyProfile,
  }) {
    return ShareBriefInfo(
      companyName: companyName ?? this.companyName,
      oldNames: oldNames ?? this.oldNames,
      companyWebsite: companyWebsite ?? this.companyWebsite,
      registerAddress: registerAddress ?? this.registerAddress,
      staffNum: staffNum ?? this.staffNum,
      registerCapital: registerCapital ?? this.registerCapital,
      lawOffice: lawOffice ?? this.lawOffice,
      accountingOffice: accountingOffice ?? this.accountingOffice,
      ceo: ceo ?? this.ceo,
      boardSecretary: boardSecretary ?? this.boardSecretary,
      officeAddress: officeAddress ?? this.officeAddress,
      companyProfile: companyProfile ?? this.companyProfile,
    );
  }
}

class Stock {
  int? id; // 序号
  String code; // 股票代号
  String name; // 股票名称
  double? changeAmount; // 涨跌额
  double changeRate; // 涨跌幅度
  int volume; // 成交量
  double amount; // 成交额
  double priceYesterdayClose; // 昨天收盘价
  double priceNow; // 最新价
  double priceMax; // 最高价
  double priceMin; // 最低价
  double priceOpen; // 开盘价
  double? priceClose; // 收盘价
  double priceAmplitude; // 股价振幅
  bool isFavorite; // 是否自选
  Stock({
    this.id,
    required this.code,
    required this.name,
    this.changeAmount,
    required this.changeRate,
    required this.volume,
    required this.amount,
    required this.priceYesterdayClose,
    required this.priceNow,
    required this.priceMax,
    required this.priceMin,
    required this.priceOpen,
    this.priceClose,
    required this.priceAmplitude,
    this.isFavorite = false,
  });
}

class StockIndex extends Stock {
  List<Share> componentShares = const []; // 指数成分股
  StockIndex({
    super.id,
    required super.code,
    required super.name,
    super.changeAmount,
    required super.changeRate,
    required super.volume,
    required super.amount,
    required super.priceYesterdayClose,
    required super.priceNow,
    required super.priceMax,
    required super.priceMin,
    required super.priceOpen,
    super.priceClose,
    required super.priceAmplitude,
    required super.isFavorite,
  });
  StockIndex copyWith({
    int? id,
    String? code,
    String? name,
    double? changeAmount,
    double? changeRate,
    int? volume,
    double? amount,
    double? priceYesterdayClose,
    double? priceNow,
    double? priceMax,
    double? priceMin,
    double? priceOpen,
    double? priceClose,
    double? priceAmplitude,
    bool? isFavorite,
  }) {
    return StockIndex(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      changeAmount: changeAmount ?? this.changeAmount,
      changeRate: changeRate ?? this.changeRate,
      volume: volume ?? this.volume,
      amount: amount ?? this.amount,
      priceYesterdayClose: priceYesterdayClose ?? this.priceYesterdayClose,
      priceNow: priceNow ?? this.priceNow,
      priceMax: priceMax ?? this.priceMax,
      priceMin: priceMin ?? this.priceMin,
      priceOpen: priceOpen ?? this.priceOpen,
      priceClose: priceClose ?? this.priceClose,
      priceAmplitude: priceAmplitude ?? this.priceAmplitude,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class Share extends Stock {
  double qrr; // 量比
  double? pe; // 市盈率
  double? pb; // 市净率
  double? roe; // 净资产收益率
  double turnoverRate; // 换手率
  // bool isFavorite; // 是否已添加自选
  double? revenue; // 当前营收
  double? bonus; // 当前分红
  double? historyBonus; // 历史分红总额
  double? historyFund; // 历史融资总额
  String? operationAnalysis; // 经营评述
  int? totalCapital; // 总市值
  int? tradeCapital; // 流通股本
  ShareIndustry? industry; // 所处行业分类
  String? industryName; // 行业名称
  Market market; // 所在交易所
  String? province; // 所在省份
  int? staffNum; // 员工数
  int? registerCapital; // 注册资本
  List<ShareConcept>? concepts; // 所属概念板块
  ShareBriefInfo? briefInfo; // 公司简要信息
  ShareBasicInfo? basicInfo; // 股票基本信息
  Share({
    super.id,
    required super.code,
    required super.name,
    super.changeAmount,
    required super.changeRate,
    required super.volume,
    required super.amount,
    required super.priceYesterdayClose,
    required super.priceNow,
    required super.priceMax,
    required super.priceMin,
    required super.priceOpen,
    super.priceClose,
    required super.priceAmplitude,
    required this.turnoverRate,
    required this.qrr,
    super.isFavorite = false,
    this.pe,
    this.pb,
    this.roe,
    this.revenue,
    this.bonus,
    this.historyBonus,
    this.historyFund,
    this.operationAnalysis,
    this.totalCapital,
    this.tradeCapital,
    this.industry,
    this.industryName,
    required this.market,
    this.province,
    this.staffNum,
    this.registerCapital,
    this.concepts,
    this.briefInfo,
    this.basicInfo,
  });

  Share copyWith({
    int? id,
    String? code,
    String? name,
    double? changeAmount,
    double? changeRate,
    int? volume,
    double? amount,
    double? priceYesterdayClose,
    double? priceNow,
    double? priceMax,
    double? priceMin,
    double? priceOpen,
    double? priceClose,
    double? priceAmplitude,
    double? qrr,
    double? pe,
    double? pb,
    double? roe,
    double? turnoverRate,
    bool? isFavorite,
    double? revenue,
    double? bonus,
    double? historyBonus,
    double? historyFund,
    String? operationAnalysis,
    int? totalCapital,
    int? tradeCapital,
    ShareIndustry? industry,
    String? industryName,
    Market? market,
    String? province,
    int? staffNum,
    int? registerCapital,
    List<ShareConcept>? concepts,
    ShareBriefInfo? briefInfo,
    ShareBasicInfo? basicInfo,
  }) {
    return Share(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      changeAmount: changeAmount ?? this.changeAmount,
      changeRate: changeRate ?? this.changeRate,
      volume: volume ?? this.volume,
      amount: amount ?? this.amount,
      priceYesterdayClose: priceYesterdayClose ?? this.priceYesterdayClose,
      priceNow: priceNow ?? this.priceNow,
      priceMax: priceMax ?? this.priceMax,
      priceMin: priceMin ?? this.priceMin,
      priceOpen: priceOpen ?? this.priceOpen,
      priceClose: priceClose ?? this.priceClose,
      priceAmplitude: priceAmplitude ?? this.priceAmplitude,
      qrr: qrr ?? this.qrr,
      pe: pe ?? this.pe,
      pb: pb ?? this.pb,
      roe: roe ?? this.roe,
      turnoverRate: turnoverRate ?? this.turnoverRate,
      isFavorite: isFavorite ?? this.isFavorite,
      revenue: revenue ?? this.revenue,
      bonus: bonus ?? this.bonus,
      historyBonus: historyBonus ?? this.historyBonus,
      historyFund: historyFund ?? this.historyFund,
      operationAnalysis: operationAnalysis ?? this.operationAnalysis,
      totalCapital: totalCapital ?? this.totalCapital,
      tradeCapital: tradeCapital ?? this.tradeCapital,
      industry: industry ?? this.industry,
      industryName: industryName ?? this.industryName,
      market: market ?? this.market,
      province: province ?? this.province,
      staffNum: staffNum ?? this.staffNum,
      registerCapital: registerCapital ?? this.registerCapital,
      concepts: concepts ?? this.concepts,
      briefInfo: briefInfo ?? this.briefInfo,
      basicInfo: basicInfo ?? this.basicInfo,
    );
  }
}

// EMA指数移动平均线
class ShareEmaCurve {
  int period; // 周期
  Color color; // 曲线显示颜色
  bool visible; // 是否显示
  List<double> emaPrice; // 收盘价简单移动平均值

  ShareEmaCurve({
    required this.period,
    required this.color,
    required this.visible,
    required this.emaPrice,
  });

  ShareEmaCurve copyWith({int? period, Color? color, bool? visible, List<double>? emaPrice}) {
    return ShareEmaCurve(
      period: period ?? this.period,
      color: color ?? this.color,
      visible: visible ?? this.visible,
      emaPrice: emaPrice ?? this.emaPrice,
    );
  }
}

// 自选股
class WatchShare {
  Share share; // share对象（Dart无需指针）
  String favoriateDate; // 添加日期
  double addPrice; // 添加自选时的股价
  double totalChangeRate; // 加入自选后的涨跌幅
  double recent5DaysChangeRate; // 最近5日涨跌幅
  double recentMonthChangeRate; // 最近1个月涨跌幅
  double recentYearChangeRate; // 今年以来涨跌幅

  WatchShare({
    required this.share,
    required this.favoriateDate,
    required this.addPrice,
    required this.totalChangeRate,
    required this.recent5DaysChangeRate,
    required this.recentMonthChangeRate,
    required this.recentYearChangeRate,
  });
  WatchShare copyWith({
    Share? share,
    String? favoriateDate,
    double? addPrice,
    double? totalChangeRate,
    double? recent5DaysChangeRate,
    double? recentMonthChangeRate,
    double? recentYearChangeRate,
  }) {
    return WatchShare(
      share: share?.copyWith() ?? this.share,
      favoriateDate: favoriateDate ?? this.favoriateDate,
      addPrice: addPrice ?? this.addPrice,
      totalChangeRate: totalChangeRate ?? this.totalChangeRate,
      recent5DaysChangeRate: recent5DaysChangeRate ?? this.recent5DaysChangeRate,
      recentMonthChangeRate: recentMonthChangeRate ?? this.recentMonthChangeRate,
      recentYearChangeRate: recentYearChangeRate ?? this.recentYearChangeRate,
    );
  }
}

// 自选股分组
class WatchShareGroup {
  String name; // 自选股分组名称
  List<WatchShare> shares;

  WatchShareGroup({required this.name, required this.shares});
}

// 监控股
class MonitorShare {
  Share share;
  String moniterDate; // 加入监控时的日期
  double monitorPrice; // 加入监控时的股价
  double expectChangeRate; // 期望跌幅
  double maxChangeRate; // 最大跌幅
  int maxDecreaseUsedDays; // 跌幅最深耗时天数
  double currentChangeRate; // 当前跌幅
  int monitorDays; // 监控天数

  MonitorShare({
    required this.share,
    required this.moniterDate,
    required this.monitorPrice,
    required this.expectChangeRate,
    required this.maxChangeRate,
    required this.maxDecreaseUsedDays,
    required this.currentChangeRate,
    required this.monitorDays,
  });
}

// K线绘制范围
class UiKlineRange {
  int begin; // 起始K线下标
  int end; // 结束K线下标

  UiKlineRange({required this.begin, required this.end});
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UiKlineRange && other.begin == begin && other.end == end;
  }

  @override
  int get hashCode => begin.hashCode ^ end.hashCode;

  // 可选：添加 toString 方便调试
  @override
  String toString() => 'UiKlineRange(begin: $begin, end: $end)';
}

// (五日)分时图数据
class MinuteKline {
  DateTime timestamp; // 交易时间戳
  String time; // 交易时间
  double price; // 价格
  double avgPrice; // 分时均价
  double changeAmount; // 涨跌额
  double changeRate; // 涨跌幅
  BigInt volume; // 成交量
  double amount; // 成交额
  BigInt totalVolume; // 累计成交量
  double totalAmount; // 累计成交额

  MinuteKline({
    required this.timestamp,
    required this.time,
    required this.price,
    required this.avgPrice,
    required this.changeAmount,
    required this.changeRate,
    required this.volume,
    required this.amount,
    required this.totalVolume,
    required this.totalAmount,
  });
}

enum UiIndicatorType {
  volume, // 成交量
  amount, // 成交额
  macd, // MACD技术指标
  kdj, // KDJ技术指标
  boll, // 布林线技术指标
  turnoverRate, // 换手率
  minuteVolume, // 分时成交量
  minuteAmount, // 分时成交额
  fiveDayMinuteVolume, // 五日分时成交量
  fiveDayMinuteAmount, // 五日分时成交额
}

// 技术指标
class UiIndicator {
  UiIndicatorType type; // 技术指标类别
  bool visible; // 是否显示
  UiIndicator({required this.type, this.visible = true});
}

// K线数据
class UiKline {
  String day; // 交易日期
  double marketCap = 0.0; // 股票市值
  double changeRate = 0.0; // 涨跌幅
  double changeAmount = 0.0; // 涨跌额
  BigInt volume; // 成交量
  double amount = 0.0; // 成交额
  double priceOpen = 0.0; // 开盘价
  double priceClose = 0.0; // 收盘价
  double priceMax = 0.0; // 最高价
  double priceMin = 0.0; // 最低价
  double priceNow = 0.0; // 当前实时价
  double turnoverRate = 0.0; // 换手率
  int danger = 0; // 1:security 2:warning 3: danger 4: damage
  int favorite = 0; // 0:not favorite 1:favorite

  UiKline({
    required this.day,
    this.marketCap = 0.0,
    this.changeRate = 0.0,
    this.changeAmount = 0.0,
    required this.volume,
    this.amount = 0.0,
    this.priceOpen = 0.0,
    this.priceClose = 0.0,
    this.priceMax = 0.0,
    this.priceMin = 0.0,
    this.priceNow = 0.0,
    this.turnoverRate = 0.0,
    this.danger = 0,
    this.favorite = 0,
  });
}

class ShareFinance {
  // 基础信息（必须）
  final String code; // 股票代码
  final int year; // 年份
  final int quarter; // 季度 (1-4)

  // 财务指标（必须）
  final double mainBusinessIncome; // 主营收入(万元)
  final double mainBusinessProfit; // 主营利润(万元)
  final double totalAssets; // 总资产(万元)
  final double currentAssets; // 流动资产(万元)
  final double fixedAssets; // 固定资产(万元)
  final double intangibleAssets; // 无形资产(万元)
  final double longTermInvestment; // 长期投资(万元)
  final double currentLiabilities; // 流动负债(万元)
  final double longTermLiabilities; // 长期负债(万元)
  final double capitalReserve; // 资本公积金(万元)
  final double perShareReserve; // 每股公积金(元)
  final double shareholderEquity; // 股东权益(万元)
  final double perShareNetAssets; // 每股净资产(元)
  final double operatingIncome; // 营业收入(万元)
  final double netProfit; // 净利润(万元)
  final double undistributedProfit; // 未分配利润(万元)
  final double perShareUndistributedProfit; // 每股未分配利润(元)
  final double perShareEarnings; // 每股收益(元)
  final double perShareCashFlow; // 每股现金流(元)
  final double perShareOperatingCashFlow; // 每股经营现金流(元)

  // 成长能力指标（可选）
  double netProfitGrowthRate; // 净利润增长率(%)
  double operatingIncomeGrowthRate; // 营业收入增长率(%)
  double totalAssetsGrowthRate; // 总资产增长率(%)
  double shareholderEquityGrowthRate; // 股东权益增长率(%)

  // 现金流指标（可选）
  double operatingCashFlow; // 经营活动产生的现金流量净额(万元)
  double investmentCashFlow; // 投资活动产生的现金流量净额(万元)
  double financingCashFlow; // 筹资活动产生的现金流量净额(万元)
  double cashIncrease; // 现金及现金等价物净增加额(万元)
  double perShareOperatingCashFlowNet; // 每股经营活动产生的现金流量净额(元)
  double perShareCashIncrease; // 每股现金及现金等价物净增加额(元)
  double perShareEarningsAfterNonRecurring; // 扣除非经常性损益后的每股收益(元)

  // 盈利能力指标（可选，自动计算）
  late double netProfitRate; // 净利润率(%)
  late double grossProfitRate; // 毛利率(%)
  late double roe; // 净资产收益率(ROE,%)
  late double roeAfterNonRecurring; // 扣除非经常性损益后的ROE(%)
  late double weightedRoe; // 加权净资产收益率(%)
  late double netProfitAfterNonRecurring; // 扣除非经常性损益后的净利润(万元)
  late double weightedRoeAfterNonRecurring; // 加权扣非ROE(%)

  // 偿债能力指标（可选，自动计算）
  late double debtRatio; // 资产负债率(%)
  late double currentRatio; // 流动比率
  late double quickRatio; // 速动比率

  // 主构造函数
  ShareFinance({
    required this.code,
    required this.year,
    required this.quarter,
    required this.mainBusinessIncome,
    required this.mainBusinessProfit,
    required this.totalAssets,
    required this.currentAssets,
    required this.fixedAssets,
    required this.intangibleAssets,
    required this.longTermInvestment,
    required this.currentLiabilities,
    required this.longTermLiabilities,
    required this.capitalReserve,
    required this.perShareReserve,
    required this.shareholderEquity,
    required this.perShareNetAssets,
    required this.operatingIncome,
    required this.netProfit,
    required this.undistributedProfit,
    required this.perShareUndistributedProfit,
    required this.perShareEarnings,
    required this.perShareCashFlow,
    required this.perShareOperatingCashFlow,

    // 可选参数（可自动计算）
    double? netProfitRate,
    double? grossProfitRate,
    double? roe,
    double? roeAfterNonRecurring,
    double? weightedRoe,
    double? netProfitAfterNonRecurring,
    double? weightedRoeAfterNonRecurring,
    double? debtRatio,
    double? currentRatio,
    double? quickRatio,

    // 成长能力指标（可选）
    this.netProfitGrowthRate = 0.0,
    this.operatingIncomeGrowthRate = 0.0,
    this.totalAssetsGrowthRate = 0.0,
    this.shareholderEquityGrowthRate = 0.0,

    // 现金流指标（可选）
    this.operatingCashFlow = 0.0,
    this.investmentCashFlow = 0.0,
    this.financingCashFlow = 0.0,
    this.cashIncrease = 0.0,
    this.perShareOperatingCashFlowNet = 0.0,
    this.perShareCashIncrease = 0.0,
    this.perShareEarningsAfterNonRecurring = 0.0,
  }) {
    // 自动计算盈利能力指标（如果未提供）
    this.netProfitRate = netProfitRate ?? (netProfit / operatingIncome * 100);
    this.grossProfitRate =
        grossProfitRate ?? ((operatingIncome - mainBusinessIncome) / operatingIncome * 100);
    this.roe = roe ?? (netProfit / shareholderEquity * 100);
    this.debtRatio = debtRatio ?? ((currentLiabilities + longTermLiabilities) / totalAssets * 100);
    this.currentRatio = currentRatio ?? (currentAssets / currentLiabilities);
    this.quickRatio = quickRatio ?? ((currentAssets - fixedAssets) / currentLiabilities);

    // 验证季度范围
    if (quarter < 1 || quarter > 4) {
      throw ArgumentError('季度必须在 1-4 之间');
    }

    // 验证财务逻辑
    if (shareholderEquity > totalAssets) {
      throw ArgumentError('股东权益不能大于总资产');
    }
  }

  // 命名构造函数：创建空对象（用于测试）
  factory ShareFinance.empty() {
    return ShareFinance(
      code: '',
      year: 0,
      quarter: 1,
      mainBusinessIncome: 0,
      mainBusinessProfit: 0,
      totalAssets: 0,
      currentAssets: 0,
      fixedAssets: 0,
      intangibleAssets: 0,
      longTermInvestment: 0,
      currentLiabilities: 0,
      longTermLiabilities: 0,
      capitalReserve: 0,
      perShareReserve: 0,
      shareholderEquity: 0,
      perShareNetAssets: 0,
      operatingIncome: 0,
      netProfit: 0,
      undistributedProfit: 0,
      perShareUndistributedProfit: 0,
      perShareEarnings: 0,
      perShareCashFlow: 0,
      perShareOperatingCashFlow: 0,
    );
  }

  // 计算同比增长率
  double calculateYoYGrowth(ShareFinance? previousYearData) {
    if (previousYearData == null || previousYearData.netProfit == 0) {
      return 0.0;
    }

    return ((netProfit - previousYearData.netProfit) / previousYearData.netProfit) * 100;
  }

  // 转换为Map
  Map<String, dynamic> serialize() {
    return {
      'code': code,
      'year': year,
      'quarter': quarter,
      'mainBusinessIncome': mainBusinessIncome,
      'mainBusinessProfit': mainBusinessProfit,
      'totalAssets': totalAssets,
      'currentAssets': currentAssets,
      'fixedAssets': fixedAssets,
      'intangibleAssets': intangibleAssets,
      'longTermInvestment': longTermInvestment,
      'currentLiabilities': currentLiabilities,
      'longTermLiabilities': longTermLiabilities,
      'capitalReserve': capitalReserve,
      'perShareReserve': perShareReserve,
      'shareholderEquity': shareholderEquity,
      'perShareNetAssets': perShareNetAssets,
      'operatingIncome': operatingIncome,
      'netProfit': netProfit,
      'undistributedProfit': undistributedProfit,
      'perShareUndistributedProfit': perShareUndistributedProfit,
      'perShareEarnings': perShareEarnings,
      'perShareCashFlow': perShareCashFlow,
      'perShareOperatingCashFlow': perShareOperatingCashFlow,
      'netProfitRate': netProfitRate,
      'grossProfitRate': grossProfitRate,
      'roe': roe,
      'roeAfterNonRecurring': roeAfterNonRecurring,
      'weightedRoe': weightedRoe,
      'netProfitAfterNonRecurring': netProfitAfterNonRecurring,
      'weightedRoeAfterNonRecurring': weightedRoeAfterNonRecurring,
      'debtRatio': debtRatio,
      'currentRatio': currentRatio,
      'quickRatio': quickRatio,
      'netProfitGrowthRate': netProfitGrowthRate,
      'operatingIncomeGrowthRate': operatingIncomeGrowthRate,
      'totalAssetsGrowthRate': totalAssetsGrowthRate,
      'shareholderEquityGrowthRate': shareholderEquityGrowthRate,
      'operatingCashFlow': operatingCashFlow,
      'investmentCashFlow': investmentCashFlow,
      'financingCashFlow': financingCashFlow,
      'cashIncrease': cashIncrease,
      'perShareOperatingCashFlowNet': perShareOperatingCashFlowNet,
      'perShareCashIncrease': perShareCashIncrease,
      'perShareEarningsAfterNonRecurring': perShareEarningsAfterNonRecurring,
    };
  }

  // 从Map创建
  factory ShareFinance.fromMap(Map<String, dynamic> map) {
    return ShareFinance(
      code: map['code'] ?? '',
      year: map['year'] ?? 0,
      quarter: map['quarter'] ?? 0,
      mainBusinessIncome: map['mainBusinessIncome']?.toDouble() ?? 0.0,
      mainBusinessProfit: map['mainBusinessProfit']?.toDouble() ?? 0.0,
      totalAssets: map['totalAssets']?.toDouble() ?? 0.0,
      currentAssets: map['currentAssets']?.toDouble() ?? 0.0,
      fixedAssets: map['fixedAssets']?.toDouble() ?? 0.0,
      intangibleAssets: map['intangibleAssets']?.toDouble() ?? 0.0,
      longTermInvestment: map['longTermInvestment']?.toDouble() ?? 0.0,
      currentLiabilities: map['currentLiabilities']?.toDouble() ?? 0.0,
      longTermLiabilities: map['longTermLiabilities']?.toDouble() ?? 0.0,
      capitalReserve: map['capitalReserve']?.toDouble() ?? 0.0,
      perShareReserve: map['perShareReserve']?.toDouble() ?? 0.0,
      shareholderEquity: map['shareholderEquity']?.toDouble() ?? 0.0,
      perShareNetAssets: map['perShareNetAssets']?.toDouble() ?? 0.0,
      operatingIncome: map['operatingIncome']?.toDouble() ?? 0.0,
      netProfit: map['netProfit']?.toDouble() ?? 0.0,
      undistributedProfit: map['undistributedProfit']?.toDouble() ?? 0.0,
      perShareUndistributedProfit: map['perShareUndistributedProfit']?.toDouble() ?? 0.0,
      perShareEarnings: map['perShareEarnings']?.toDouble() ?? 0.0,
      perShareCashFlow: map['perShareCashFlow']?.toDouble() ?? 0.0,
      perShareOperatingCashFlow: map['perShareOperatingCashFlow']?.toDouble() ?? 0.0,
      netProfitRate: map['netProfitRate']?.toDouble(),
      grossProfitRate: map['grossProfitRate']?.toDouble(),
      roe: map['roe']?.toDouble(),
      debtRatio: map['debtRatio']?.toDouble(),
      currentRatio: map['currentRatio']?.toDouble(),
      quickRatio: map['quickRatio']?.toDouble(),
      netProfitGrowthRate: map['netProfitGrowthRate']?.toDouble() ?? 0.0,
      operatingIncomeGrowthRate: map['operatingIncomeGrowthRate']?.toDouble() ?? 0.0,
      totalAssetsGrowthRate: map['totalAssetsGrowthRate']?.toDouble() ?? 0.0,
      shareholderEquityGrowthRate: map['shareholderEquityGrowthRate']?.toDouble() ?? 0.0,
      operatingCashFlow: map['operatingCashFlow']?.toDouble() ?? 0.0,
      investmentCashFlow: map['investmentCashFlow']?.toDouble() ?? 0.0,
      financingCashFlow: map['financingCashFlow']?.toDouble() ?? 0.0,
      cashIncrease: map['cashIncrease']?.toDouble() ?? 0.0,
      perShareOperatingCashFlowNet: map['perShareOperatingCashFlowNet']?.toDouble() ?? 0.0,
      perShareCashIncrease: map['perShareCashIncrease']?.toDouble() ?? 0.0,
      perShareEarningsAfterNonRecurring:
          map['perShareEarningsAfterNonRecurring']?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'ShareFinance{code: $code, year: $year, quarter: $quarter, ROE: $roe%, 净利润: $netProfit万元, 净利润率: $netProfitRate%}';
  }
}

bool isUpLimitPrice(UiKline kline, Share pShare) {
  // 检查股票是否是ST股票
  if (isStShare(pShare)) {
    if (kline.changeRate >= 0.05) {
      // 检查涨幅是否达到5%
      return true; // 涨停板
    }
    return false;
  }

  // 检查股票是否是上市第一天，名称中带N的，没有涨跌幅限制
  if (pShare.name.indexOf("N") == 0) {
    return false;
  }

  if (pShare.market == Market.shangHai || pShare.market == Market.shenZhen) {
    // 检查股票所在市场是否是深圳主板和上海主板，10%的涨幅限制
    if (kline.changeRate >= 0.093) {
      return true;
    }
    return false;
  } else if (pShare.market == Market.chuangYeBan || pShare.market == Market.keChuangBan) {
    // 检查股票所在市场是否是创业板或者科创板，20%的涨幅限制
    if (kline.changeRate >= 0.1993) {
      return true;
    }
    return false;
  } else if (pShare.market == Market.beiJiaoSuo) {
    // 检查股票所在市场是否是北交所，30%的涨幅限制
    if (kline.changeRate >= 0.2993) {
      return true;
    }
    return false;
  }
  return false;
}

bool isDownLimitPrice(UiKline kline, Share pShare) {
  // 检查股票是否是ST股票
  if (isStShare(pShare)) {
    if (kline.changeRate <= -0.05) {
      // 检查涨幅是否达到5%
      return true; // 跌停板
    }
    return false;
  }

  // 检查股票是否是上市第一天，名称中带N的，没有涨跌幅限制
  if (!pShare.name.contains("N")) {
    return false;
  }

  if (pShare.market == Market.shangHai || pShare.market == Market.shenZhen) {
    // 检查股票所在市场是否是深圳主板和上海主板，10%的跌幅限制
    if (kline.changeRate <= -0.093) {
      return true;
    }
    return false;
  } else if (pShare.market == Market.chuangYeBan || pShare.market == Market.keChuangBan) {
    // 检查股票所在市场是否是创业板或者科创板，20%的跌幅限制
    if (kline.changeRate <= -0.1993) {
      return true;
    }
    return false;
  } else if (pShare.market == Market.beiJiaoSuo) {
    // 检查股票所在市场是否是北交所，30%的跌幅限制
    if (kline.changeRate <= -0.2993) {
      return true;
    }
    return false;
  }
  return false;
}

bool isStShare(Share pShare) {
  if (pShare.name.contains("ST")) {
    // 检查股票名称是否以"ST"开头
    return true;
  }
  return false;
}

double getShareUpLimitPrice(Share pShare) {
  if (pShare.code.substring(0, 1) == "N") {
    // 新股，没有涨跌幅限制
    return pShare.priceYesterdayClose * (1 + 0.44);
  } else if (pShare.code.substring(0, 2) == "ST") {
    // ST股，5%涨跌幅限制
    return pShare.priceYesterdayClose * (1 + 0.05);
  } else if (pShare.code.substring(0, 3) == "688" || pShare.code.substring(0, 3) == "300") {
    // 科创板和创业板股票, 20%涨跌幅限制
    return pShare.priceYesterdayClose * (1 + 0.2);
  } else if (pShare.code.substring(0, 1) == "8") {
    // 北交所股票，30%涨跌幅限制
    return pShare.priceYesterdayClose * (1 + 0.3);
  } else {
    // 沪深主板股票，10%涨跌幅限制
    return pShare.priceYesterdayClose * (1 + 0.1);
  }
}

double getShareDownLimitPrice(Share pShare) {
  if (pShare.code.substring(0, 1) == "N") {
    // 新股，没有涨跌幅限制
    return pShare.priceYesterdayClose * (1 - 0.44);
  } else if (pShare.code.substring(0, 2) == "ST") {
    // ST股，5%涨跌幅限制
    return pShare.priceYesterdayClose * (1 - 0.05);
  } else if (pShare.code.substring(0, 3) == "688" || pShare.code.substring(0, 3) == "300") {
    // 科创板和创业板股票, 20%涨跌幅限制
    return pShare.priceYesterdayClose * (1 - 0.2);
  } else if (pShare.code.substring(0, 1) == "8") {
    // 北交所股票，30%涨跌幅限制
    return pShare.priceYesterdayClose * (1 - 0.3);
  } else {
    // 沪深主板股票，10%涨跌幅限制
    return pShare.priceYesterdayClose * (1 - 0.1);
  }
}
