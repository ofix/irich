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
import "package:irich/service/api_provider_capabilities.dart";
import "package:irich/service/api_providers/api_provider.dart";
import "package:irich/global/stock.dart";
import "package:irich/service/request_log.dart";

// 东方财富分时K线 URL 生成函数
String klineUrlEastMoneyMinute(String shareCode, int market) {
  return "https://83.push2.eastmoney.com/api/qt/stock/trends2/"
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
  return "https://48.push2.eastmoney.com/api/qt/stock/trends2/"
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
      default:
        throw UnimplementedError('Unsupported API type: $ProviderApiType');
    }
  }

  // 根据请求类型解析响应数据
  @override
  dynamic parseResponse(ProviderApiType apiType, dynamic response) {
    switch (apiType) {
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
      default:
        throw UnimplementedError('Unsupported API type: $ProviderApiType');
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
    final name = params['code']; // 板块代号,东方财富限制了
    final responses = <ApiResult>[];
    int pageTotal = 0;
    int pageDone = 0;
    double pageProgress = 0.0;

    for (int i = 1; i <= 30; i++) {
      // 每页100条记录，假设最多20个分页，也即2000个成分股
      final url =
          "https://push2.eastmoney.com/api/qt/clist/get?np=1&fltt=1&invt=2&po=1&dect=1&fid=f3&fs=b:$name&fields=f12,f14&pn=$i&pz=100";
      try {
        DateTime requestTime = DateTime.now();
        final result = await getRawJson(url);
        DateTime responseTime = DateTime.now();
        if (i == 1) {
          final json = jsonDecode(result.response);
          pageTotal = json['data']['total'];
        }
        pageDone += 100;
        pageProgress = pageDone / pageTotal;
        if (pageDone >= pageTotal) {
          pageProgress = 1;
        }
        if (_isPageEnd(result.response)) break;
        responses.add(result);
        // 随机延时
        final random = Random();
        int delaySeconds = 3 + random.nextInt(3); // 随机 1~2 秒
        final requestLog = RequestLog(
          taskId: params['TaskId'],
          providerId: provider,
          apiType: apiType,
          responseBytes: result.responseBytes,
          requestTime: requestTime,
          responseTime: responseTime,
          url: url,
          statusCode: result.statusCode,
          duration: responseTime.difference(requestTime).inMilliseconds,
          pageProgress: pageProgress,
        );
        onPagerProgress?.call(requestLog);
        await Future.delayed(Duration(seconds: delaySeconds));
      } catch (e) {
        rethrow;
      }
    }
    return responses;
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
    final url = klineUrlEastMoney(params['ShareCode'], 0, 1);
    try {
      return getJson(url);
    } catch (e) {
      rethrow;
    }
  }

  List<UiKline> parseDayKline(String response) {
    final List<UiKline> uiKlines = [];
    // 解析JSON数据
    final dynamic result = jsonDecode(response);
    final List<dynamic> klines = result["data"]["klines"];
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
    final url = klineUrlEastMoneyMinute(params['ShareCode'], 3);
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
        timestamp: DateTime.parse(fields[1]),
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
}
