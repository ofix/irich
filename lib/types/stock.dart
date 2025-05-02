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
  static Market fromValue(int value) {
    return Market.values.firstWhere(
      (e) => e.market == value,
      orElse: () => throw ArgumentError('Invalid market value: $value'),
    );
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
  year, // 年K线
  all, // 以上所有K线
}

// 在KlineType枚举中添加扩展方法
extension KlineTypeExtension on KlineType {
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
}

class Share {
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
  double qrr; // 量比
  double? pe; // 市盈率
  double? pb; // 市净率
  double? roe; // 净资产收益率
  double turnoverRate; // 换手率
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
    required this.turnoverRate,
    required this.qrr,
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
}

// 自选股
class FavoriteShare {
  Share share; // share对象（Dart无需指针）
  String favoriateDate; // 添加日期
  double addPrice; // 添加自选时的股价
  double totalChangeRate; // 加入自选后的涨跌幅
  double recent5DaysChangeRate; // 最近5日涨跌幅
  double recentMonthChangeRate; // 最近1个月涨跌幅
  double recentYearChangeRate; // 今年以来涨跌幅

  FavoriteShare({
    required this.share,
    required this.favoriateDate,
    required this.addPrice,
    required this.totalChangeRate,
    required this.recent5DaysChangeRate,
    required this.recentMonthChangeRate,
    required this.recentYearChangeRate,
  });
}

// 自选股分组
class FavoriteShareGroup {
  String name; // 自选股分组名称
  List<FavoriteShare> shares;

  FavoriteShareGroup({required this.name, required this.shares});
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
  int height; // 指标的高度
  UiIndicator({required this.type, this.visible = false, this.height = 200});
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
