// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/api_providers/api_provider_eastmoney.dart
// Purpose:     east money api provider
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

// ignore_for_file: avoid_print
import "dart:convert";
import "dart:math";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:irich/service/api_provider_capabilities.dart";
import "package:irich/service/api_providers/api_provider.dart";
import "package:irich/global/stock.dart";
import "package:irich/service/request_log.dart";

// 东方财富股票列表 URL 生成函数
String quoteUrlEastMoney(int pageOffset, int pageSize) {
  return "https://push2.eastmoney.com/api/qt/clist/get"
      "?pn=$pageOffset"
      "&pz=$pageSize"
      "&po=1"
      "&np=1"
      "&fltt=1"
      "&dect=1"
      "&fid=f3"
      "wbp2u=|0|0|0|web"
      "&fs=m:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23,m:0+t:81+s:2048" // 0: 沪市, 1: 深市, 6: A股
      "&fields=f12,f13,f14,f1,f2,f4,f3,f152,f5,f6,f7,f15,f18,f16,f17,f10,f8,f9";
}

// 东方财富分时K线 URL 生成函数
String klineUrlEastMoneyMinute(String shareCode, int market) {
  return "https://78.push2his.eastmoney.com/api/qt/stock/trends2/"
      "sse?fields1=f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14,f17"
      "&fields2=f51,f52,f53,f54,f55,f56,f57,f58"
      "&mpi=1000"
      "&secid=$market.$shareCode"
      "&ndays=1"
      "&iscr=0"
      "&iscca=0";
}

// 东方财富5日分时K线 URL 生成函数
String klineUrlEastMoneyFiveDay(String shareCode, int market) {
  return "https://53.push2.eastmoney.com/api/qt/stock/trends2/"
      "sse?fields1=f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14,f17"
      "&fields2=f51,f52,f53,f54,f55,f56,f57,f58"
      "&mpi=1000"
      "&secid=$market.$shareCode"
      "&ndays=5"
      "&iscr=0"
      "&iscca=0";
}

// 东方财富行情中心 K 线数据 URL 生成函数
String klineUrlEastMoney(String shareCode, int market, int klineType) {
  return "https://push2his.eastmoney.com/api/qt/stock/kline/get"
      "?fields1=f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13"
      "&fields2=f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61"
      "&begin=0"
      "&end=20500101"
      "&rtntype=6"
      "&lmt=1000000"
      "&secid=$market.$shareCode&klt=$klineType&fqt=1";
}

String bkUrlEastMoney(String bkName, int pageIndex, [int pageSize = 100]) {
  return "https://push2.eastmoney.com/api/qt/clist/get"
      "?np=1"
      "&fltt=1"
      "&invt=2"
      "&po=1"
      "&dect=1"
      "&fid=f3"
      "&fs=b:$bkName"
      "&fields=f12,f14"
      "&pn=$pageIndex&pz=$pageSize";
}

String stockIndexUrlShangHaiEastMoney(int pageIndex, [int pageSize = 100]) {
  return "https://push2.eastmoney.com/api/qt/clist/get"
      "?np=1"
      "&fltt=1"
      "&invt=2"
      "&fs=m:1+t:1"
      "&fields=f12,f13,f14,f1,f2,f4,f3,f152,f5,f6,f7,f15,f18,f16,f17,f10"
      "&fid=f3"
      "&pn=$pageIndex"
      "&pz=$pageSize"
      "&po=1&dect=1&wbp2u=|0|0|0|web";
}

String stockIndexUrlShenZhenEastMoney(int pageIndex, [int pageSize = 100]) {
  return "https://push2.eastmoney.com/api/qt/clist/get"
      "?np=1"
      "&fltt=1"
      "&invt=2"
      "&fs=m:0+t:5"
      "&fields=f12,f13,f14,f1,f2,f4,f3,f152,f5,f6,f7,f15,f18,f16,f17,f10"
      "&fid=f3"
      "&pn=$pageIndex"
      "&pz=$pageSize"
      "&po=1&dect=1&wbp2u=|0|0|0|web";
}

// 2. 实现具体数据源（示例：东方财富）
class ApiProviderEastMoney extends ApiProvider {
  @override
  final provider = EnumApiProvider.eastMoney;

  @override
  Future<dynamic> doRequest(
    ProviderApiType apiType,
    Map<String, dynamic> params, [
    void Function(RequestLog requestLog)? onPagerProgress,
  ]) async {
    switch (apiType) {
      case ProviderApiType.quote:
        return fetchQuote();
      case ProviderApiType.quoteExtra:
        return fetchQuoteExtra(params);
      case ProviderApiType.industry:
      case ProviderApiType.concept:
      case ProviderApiType.province:
        return fetchBk(params, apiType, onPagerProgress); // 地域/行业/概念板块数据
      case ProviderApiType.dayKline:
        return fetchDayKline(params);
      case ProviderApiType.fiveDayKline:
        return fetchFiveDayKline(params);
      case ProviderApiType.minuteKline:
        return fetchMinuteKline(params);
      case ProviderApiType.indexList:
        return fetchIndexList(params, apiType, onPagerProgress); // 加载指数列表
      default:
        throw UnimplementedError('Unsupported API type: $ProviderApiType');
    }
  }

  // 根据请求类型解析响应数据
  @override
  dynamic parseResponse(ProviderApiType apiType, dynamic response) {
    switch (apiType) {
      case ProviderApiType.quote:
        return response; // 股票列表数据
      case ProviderApiType.quoteExtra:
        return parseQuoteExtra(response); // 侧边栏数据
      case ProviderApiType.industry:
      case ProviderApiType.concept:
      case ProviderApiType.province:
        return parseBk(response); // 地域/行业/概念板块数据
      case ProviderApiType.dayKline:
        return parseDayKline(response); // 日K线数据
      case ProviderApiType.fiveDayKline:
        return parseFiveDayKline(response); // 5日K线分时数据
      case ProviderApiType.minuteKline:
        return parseMinuteKline(response); // 分时K线数据
      case ProviderApiType.indexList:
        return parseIndexList(response);
      default:
        throw UnimplementedError('Unsupported API type: $ProviderApiType');
    }
  }

  // 获取东方财富股票列表
  Future<dynamic> fetchQuote() async {
    try {
      const int pageSize = 100; // 每页100条数据
      int total = 6000; // 假设总共有6000条数据
      int pageOffset = 1; // 从第一页开始
      final List<Share> marketShares = [];

      for (int i = 0; i < total;) {
        final url = quoteUrlEastMoney(pageOffset, pageSize);
        debugPrint("[东方财富][行情] $url");
        final result = await getJson(url);

        final response = jsonDecode(result.response);
        final data = response['data']['diff'] as List<dynamic>;
        if (i == 0) {
          total = response['data']['total'] as int; // 获取总条数
          debugPrint("[东方财富][行情] 股票总数: $total");
        }
        for (final item in data) {
          marketShares.add(
            Share(
              code: item['f12'], // 股票代码
              name: item['f14'], // 股票名称
              market: getMarket(item['f1'] as int), // 市场代码
              priceYesterdayClose: (item['f18'] as num).toDouble() / 100, // 昨日收盘价
              priceNow: (item['f2'] as num).toDouble() / 100, // 当前价格
              priceAmplitude: (item['f7'] as num).toDouble() / 100, // 振幅
              qrr:
                  (item['f10'] is num)
                      ? (item['f10'] as num).toDouble() / 100
                      : (item['f10'] is String)
                      ? double.tryParse(item['f10']) ?? 0.0
                      : 0.0, // 量比
              changeRate: (item['f3'] as num).toDouble() / 100, // 涨跌幅
              volume: item['f5'], // 成交量
              amount: (item['f6'] as num).toDouble(), // 成交额
              priceOpen: (item['f17'] as num).toDouble() / 100, // 开盘价
              priceMax: (item['f15'] as num).toDouble() / 100, // 最高价
              priceMin: (item['f16'] as num).toDouble() / 100, // 最低价
              priceClose: (item['f2'] as num).toDouble() / 100, // 收盘价
              turnoverRate: (item['f8'] as num).toDouble() / 100, // 换手率
              pe: (item['f9'] is num) ? (item['f9'] as num).toDouble() : 0.0, // 市盈率(动态)
            ),
          );
        }
        i += data.length; // 累加已获取的条数
        if (i >= total) break; // 如果已获取条数大于等于总条数，则结束循环
        pageOffset++; // 分页处理，下一页
      }
      return marketShares;
    } catch (e, stackTrace) {
      throw Exception('Failed to fetch market shares: ${stackTrace.toString()}');
    }
  }

  // 获取侧边栏数据
  Future<ApiResult> fetchQuoteExtra(Map<String, dynamic> params) async {
    final url = "https://quote.eastmoney.com/center/api/sidemenu_new.json";
    try {
      return getJson(url);
    } catch (e) {
      rethrow;
    }
  }

  List<List<Map<String, dynamic>>> parseQuoteExtra(ApiResult result) {
    final List<Map<String, dynamic>> concepts = [];
    final List<Map<String, dynamic>> industries = [];
    final List<Map<String, dynamic>> provinces = [];
    final List<List<Map<String, dynamic>>> menu = [];
    // 解析JSON数据
    final response = jsonDecode(result.response);
    final List<dynamic> bklist = response["bklist"]; // 行业/概念/地域板块列表
    for (final bk in bklist) {
      final int type = bk["type"];
      if (type == 1) {
        provinces.add(bk); // 地域板块
      } else if (type == 2) {
        industries.add(bk); // 行业板块
      } else if (type == 3) {
        concepts.add(bk); // 概念板块
      }
    }
    menu.addAll([provinces, industries, concepts]);
    return menu;
  }

  Future<List<ApiResult>> fetchBk(
    Map<String, dynamic> params,
    ProviderApiType apiType, [
    void Function(RequestLog requestLog)? onPagerProgress,
  ]) async {
    String generateUrl(int pageIndex, int pageSize, Map<String, dynamic> _) =>
        bkUrlEastMoney(params['code'], pageIndex, pageSize);
    return _multiPageRequest(params, apiType, onPagerProgress, [generateUrl]);
  }

  bool _isPageEnd(String data) {
    return !data.contains('"data":{');
  }

  List<String> parseBk(List<ApiResult> responses) {
    final List<String> shareList = [];
    // 解析JSON数据
    for (final item in responses) {
      final result = jsonDecode(item.response);
      final data = result["data"]['diff'];
      for (final row in data) {
        final String shareCode = row["f12"]; // 股票名称
        shareList.add(shareCode);
      }
    }
    return shareList;
  }

  // 获取日K线数据
  Future<ApiResult> fetchDayKline(Map<String, dynamic> params) async {
    // 日K线
    int marketCode = getMarketCode(params['Market']);
    int klineType = getKlineType(KlineType.day);
    final url = klineUrlEastMoney(params['ShareCode'], marketCode, klineType);
    debugPrint("加载东方财富日K线: $url");
    try {
      return getJson(url);
    } catch (e) {
      rethrow;
    }
  }

  int getMarketCode(Market market) {
    if (market == Market.shenZhen) {
      return 0;
    } else if (market == Market.shangHai) {
      return 1;
    } else if (market == Market.chuangYeBan) {
      return 0;
    } else if (market == Market.keChuangBan) {
      return 1;
    } else if (market == Market.beiJiaoSuo) {
      return 0;
    }
    return 0;
  }

  Market getMarket(int marketCode) {
    if (marketCode == 0) {
      return Market.shenZhen;
    } else if (marketCode == 1) {
      return Market.shangHai;
    }
    return Market.shenZhen; // 默认返回深市
  }

  int getKlineType(KlineType klineType) {
    if (klineType == KlineType.day) {
      return 101;
    } else if (klineType == KlineType.week) {
      return 102;
    } else if (klineType == KlineType.month) {
      return 103;
    } else if (klineType == KlineType.quarter) {
      return 104;
    } else if (klineType == KlineType.year) {
      return 106;
    }
    return 0;
  }

  List<UiKline> parseDayKline(ApiResult result) {
    final List<UiKline> uiKlines = [];
    // 解析JSON数据
    final dynamic response = jsonDecode(result.response);
    final List<dynamic> klines = response["data"]["klines"];
    for (final row in klines) {
      final List<String> fields = row.split(',');
      // 处理数值转换（Dart 无 stod，用 tryParse 替代）
      double parseField(String str) => double.tryParse(str) ?? 0.0;

      final uiKline = UiKline(
        day: fields[0],
        priceOpen: parseField(fields[1]),
        priceClose: parseField(fields[2]),
        priceMax: parseField(fields[3]),
        priceMin: parseField(fields[4]),
        volume: BigInt.parse(fields[5]),
        amount: parseField(fields[6]),
        changeRate: parseField(fields[8]),
        changeAmount: parseField(fields[9]),
        turnoverRate: parseField(fields[10]),
      );
      uiKlines.add(uiKline);
    }
    return uiKlines;
  }

  // 获取分时K线数据
  Future<ApiResult> fetchMinuteKline(Map<String, dynamic> params) async {
    int marketCode = getMarketCode(params['Market']);
    final url = klineUrlEastMoneyMinute(params['ShareCode'], marketCode);
    try {
      return getJson(url);
    } catch (e) {
      rethrow;
    }
  }

  // 解析分时K线数据
  List<MinuteKline?> parseMinuteKline(ApiResult result) {
    final minuteKlines = <MinuteKline>[];
    // 解析JSON数据
    final response = jsonDecode(result.response);
    final data = response["data"]["trends"] as String;
    final rows = data.split(';');
    for (final row in rows) {
      final fields = row.split(',');
      final kline = MinuteKline(
        timestamp: DateFormat("MM-dd HH:mm").parse(fields[1]),
        time: fields[1],
        price: double.parse(fields[2]),
        avgPrice: double.parse(fields[3]),
        changeAmount: double.parse(fields[4]),
        changeRate: double.parse(fields[5]),
        volume: BigInt.parse(fields[6]),
        amount: double.parse(fields[7]),
        totalVolume: BigInt.parse(fields[8]),
        totalAmount: double.parse(fields[9]),
      );
      minuteKlines.add(kline);
    }
    return minuteKlines;
  }

  // 获取五日分时数据
  Future<ApiResult> fetchFiveDayKline(Map<String, dynamic> params) async {
    // 日K线
    final url = klineUrlEastMoneyFiveDay(params['ShareCode'], 0);
    try {
      return getJson(url);
    } catch (e) {
      rethrow;
    }
  }

  List<UiKline> parseFiveDayKline(ApiResult result) {
    final List<UiKline> uiKlines = [];
    // 解析JSON数据
    final response = jsonDecode(result.response);
    final List<dynamic> klines = response["data"]["klines"];
    for (final row in klines) {
      final List<String> fields = row.split(',');
      // 处理数值转换（Dart 无 stod，用 tryParse 替代）
      double parseField(String str) => double.tryParse(str) ?? 0.0;

      final uiKline = UiKline(
        day: fields[0],
        priceOpen: parseField(fields[1]),
        priceClose: parseField(fields[2]),
        priceMax: parseField(fields[3]),
        priceMin: parseField(fields[4]),
        volume: BigInt.parse(fields[5]),
        amount: parseField(fields[6]),
        changeRate: parseField(fields[8]),
        changeAmount: parseField(fields[9]),
        turnoverRate: parseField(fields[10]),
      );
      uiKlines.add(uiKline);
    }
    return uiKlines;
  }

  // 东方财富多个分页请求通用回调处理函数
  Future<List<ApiResult>> _multiPageRequest(
    Map<String, dynamic> params,
    ProviderApiType apiType,
    void Function(RequestLog requestLog)? onPagerProgress,
    List<String Function(int pageIndex, int pageSize, Map<String, dynamic> params)> urlGenerators,
  ) async {
    List<ApiResult> responses = [];
    const int pageSize = 100;
    int totalRecords = 0;
    List<int> subTotalRecords = [];
    int recvRecords = 0;
    final random = Random(); // 随机延时
    // 先累加所有分页请求的记录总数
    for (final generateUrl in urlGenerators) {
      final url = generateUrl(1, pageSize, params);
      final result = await getJson(url);
      final json = jsonDecode(result.response);
      int total = json['data']['total'] as int;
      totalRecords += total;
      subTotalRecords.add(total);
      recvRecords += pageSize;
      responses.add(result);
      await Future.delayed(Duration(seconds: 3 + random.nextInt(2)));
    }
    // 准确返回进度
    for (int i = 1; i <= urlGenerators.length; i++) {
      _notifyProgress(
        params: params,
        apiType: apiType,
        result: responses[i],
        pageProgress: min(1.0, i * pageSize / totalRecords),
        onPagerProgress: onPagerProgress,
      );
    }

    for (int i = 0; i < urlGenerators.length; i++) {
      final generateUrl = urlGenerators[i];
      int maxPage = (subTotalRecords[i] / pageSize).ceil();
      for (int pageIndex = 2; pageIndex <= maxPage; pageIndex++) {
        final url = generateUrl(pageIndex, pageSize, params);
        final result = await getJson(url);
        recvRecords += pageSize;
        final progress = min(1.0, recvRecords / totalRecords);
        responses.add(result);
        _notifyProgress(
          params: params,
          apiType: apiType,
          result: result,
          pageProgress: progress,
          onPagerProgress: onPagerProgress,
        );
        if (_isPageEnd(result.response)) break;
        await Future.delayed(Duration(seconds: 3 + random.nextInt(2)));
      }
    }
    return responses;
  }

  // 通知进度
  void _notifyProgress({
    required Map<String, dynamic> params,
    required ProviderApiType apiType,
    required ApiResult result,
    required double pageProgress,
    void Function(RequestLog requestLog)? onPagerProgress,
  }) {
    onPagerProgress?.call(
      RequestLog(
        taskId: params['TaskId'],
        providerId: provider,
        apiType: apiType,
        responseBytes: result.responseBytes,
        requestTime: result.requestTime!,
        responseTime: result.responseTime!,
        url: result.url,
        statusCode: result.statusCode,
        duration: result.responseTime!.difference(result.requestTime!).inMilliseconds,
        pageProgress: pageProgress,
      ),
    );
  }

  // 抓取东方财富的指数列表
  Future<List<ApiResult>> fetchIndexList(
    Map<String, dynamic> params,
    ProviderApiType apiType,
    void Function(RequestLog requestLog)? onPagerProgress,
  ) async {
    String shanghaiUrl(int pageIndex, int _, __) => stockIndexUrlShangHaiEastMoney(pageIndex);
    String shenzhenUrl(int pageIndex, int _, __) => stockIndexUrlShenZhenEastMoney(pageIndex);
    return _multiPageRequest(params, apiType, onPagerProgress, [shanghaiUrl, shenzhenUrl]);
  }

  List<StockIndex> parseIndexList(List<ApiResult> responses) {
    final List<StockIndex> stockIndexes = [];
    for (final item in responses) {
      final result = jsonDecode(item.response);
      final data = result["data"]['diff'];
      for (final row in data) {
        final stockIndex = StockIndex(
          code: row['f1'],
          name: row['f2'],
          changeRate: row['f3'],
          volume: row['f4'],
          amount: row['f5'],
          priceYesterdayClose: row['f6'],
          priceNow: row['f7'],
          priceMax: row['f8'],
          priceMin: row['f9'],
          priceOpen: row['f10'],
          priceAmplitude: row['f11'],
          isFavorite: false,
        );
        stockIndexes.add(stockIndex);
      }
    }
    return stockIndexes;
  }
}
