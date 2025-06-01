// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/api_providers/api_provider_baidu.dart
// Purpose:     baidu finance api provider
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

// ignore_for_file: avoid_print
import "dart:convert";

import "package:flutter/material.dart";
import "package:irich/global/stock.dart";
import "package:irich/service/api_providers/api_provider.dart";
import "package:irich/service/api_provider_capabilities.dart";
import "package:irich/service/request_log.dart";

// 百度股市通 K 线数据 URL 生成函数
String klineUrlFinanceBaidu(String shareCode, String klineType, String extra) {
  return "http://finance.pae.baidu.com/vapi/v1/getquotation"
      "?srcid=5353"
      "&pointType=string"
      "&group=quotation_kline_ab"
      "&query=$shareCode&code=$shareCode"
      "&market_type=ab"
      "&newFormat=1"
      "&is_kc=0"
      "&ktype=$klineType&finClientType=pc$extra&finClientType=pc";
}

// 百度股市通分时走势图 URL 生成函数
String klineUrlFinanceBaiduMinute(String shareCode) {
  return "http://finance.pae.baidu.com/vapi/v1/getquotation"
      "?srcid=5353"
      "&pointType=string"
      "&group=quotation_minute_ab"
      "&query=$shareCode&code=$shareCode"
      "&market_type=ab"
      "&new_Format=1"
      "&finClientType=pc";
}

// 百度股市通近5日分时走势图 URL 生成函数
String klineUrlFinanceBaiduFiveDay(String shareCode, String shareName) {
  return "http://finance.pae.baidu.com/vapi/v1/getquotation"
      "?srcid=5353"
      "&pointType=string"
      "&group=quotation_fiveday_ab"
      "&query=$shareCode&code=$shareCode&name=$shareName"
      "&market_type=ab"
      "&new_Format=1"
      "&finClientType=pc";
}

// 3. 实现百度财经数据源（支持分页）
class ApiProviderBaidu extends ApiProvider {
  @override
  final provider = EnumApiProvider.baiduFinance;

  @override
  Future<dynamic> doRequest(
    ProviderApiType apiType,
    Map<String, dynamic> params, [
    void Function(RequestLog requestLog)? onPagerProgress,
  ]) async {
    switch (apiType) {
      case ProviderApiType.dayKline:
        return fetchDayKline(params);
      case ProviderApiType.minuteKline:
        return fetchMinuteKline(params);
      case ProviderApiType.fiveDayKline:
        return fetchFiveDayKline(params);
      default:
        throw UnimplementedError('Unsupported API type: $ProviderApiType');
    }
  }

  // 根据请求类型解析响应数据
  @override
  dynamic parseResponse(ProviderApiType apiType, dynamic response) {
    switch (apiType) {
      case ProviderApiType.dayKline:
        return parseDayKline(response); // 日K线数据
      case ProviderApiType.fiveDayKline:
      case ProviderApiType.minuteKline:
        return parseMinuteKline(response); // 分时K线数据，5日K线分时数据
      default:
        throw UnimplementedError('Unsupported API type: $ProviderApiType');
    }
  }

  String getKlineType(KlineType klineType) {
    if (klineType == KlineType.day) {
      return "day";
    } else if (klineType == KlineType.week) {
      return "week";
    } else if (klineType == KlineType.month) {
      return "month";
    } else if (klineType == KlineType.quarter) {
      return "quarter";
    } else if (klineType == KlineType.year) {
      return "year";
    } else if (klineType == KlineType.minute) {
      return "minute";
    } else if (klineType == KlineType.fiveDay) {
      return "five_day";
    }
    return "";
  }

  // 日K线数据
  Future<ApiResult> fetchDayKline(Map<String, dynamic> params) async {
    String extra = "";
    if (params.containsKey("EndDate") && params['EndDate'] != "") {
      extra = "&end_time= ${params['EndDate']}&count=${params['Count']}";
    }

    final url = klineUrlFinanceBaidu(
      params['ShareCode'],
      getKlineType(KlineType.day), // 日K线
      extra,
    );
    debugPrint("加载百度财经日K线: $url");
    try {
      return await getJson(url);
    } catch (e) {
      rethrow;
    }
  }

  // 处理数值转换（Dart 无 stod，用 tryParse 替代）
  double parseField(String str) => double.tryParse(str) ?? 0.0;

  List<UiKline> parseDayKline(ApiResult result) {
    final List<UiKline> uiKlines = [];
    // 解析JSON数据
    try {
      final dynamic response = jsonDecode(result.response);
      final data = response["Result"]["newMarketData"]['marketData'] as String? ?? '';

      if (data.isNotEmpty) {
        final rows = data.split(';');
        for (final row in rows) {
          if (row.isEmpty) continue;

          final fields = row.split(',');
          if (fields.length < 11) continue;

          final uiKline = UiKline(
            day: fields[1],
            priceOpen: parseField(fields[2]),
            priceClose: parseField(fields[3]),
            volume: (BigInt.tryParse(fields[4]) ?? BigInt.zero) ~/ BigInt.from(100),
            priceMax: parseField(fields[5]),
            priceMin: parseField(fields[6]),
            amount: parseField(fields[7]),
            changeAmount: parseField(fields[8]),
            changeRate: parseField(fields[9]),
            turnoverRate: parseField(fields[10]),
          );
          uiKlines.add(uiKline);
        }
      }
    } catch (e) {
      print('Error parsing day kline: $e');
    }
    return uiKlines;
  }

  // 分时K线
  Future<ApiResult> fetchMinuteKline(Map<String, dynamic> params) async {
    final url = klineUrlFinanceBaiduMinute(params['ShareCode']);
    try {
      return await getJson(url);
    } catch (e) {
      rethrow;
    }
  }

  // 解析分时K线数据
  List<MinuteKline?> parseMinuteKline(ApiResult result) {
    final minuteKlines = <MinuteKline>[];
    // 解析JSON数据
    final response = jsonDecode(result.response);
    final days = response['Result']['newMarketData']['marketData'] as List<dynamic>? ?? [];
    for (final day in days) {
      final data = day['p'] as String? ?? '';
      if (data.isEmpty) continue;

      final rows = data.split(';');
      for (final row in rows) {
        if (row.isEmpty) continue;

        final fields = row.split(',');
        if (fields.length < 10) continue;

        final minuteKline = MinuteKline(
          timestamp: DateTime.parse(fields[1]),
          time: fields[1],
          price: parseField(fields[2]),
          avgPrice: parseField(fields[3]),
          changeAmount: parseField(fields[4]),
          changeRate: parseField(fields[5]),
          volume: (BigInt.tryParse(fields[6]) ?? BigInt.zero),
          amount: parseField(fields[7]),
          totalVolume: (BigInt.tryParse(fields[8]) ?? BigInt.zero),
          totalAmount: parseField(fields[9]),
        );

        minuteKlines.add(minuteKline);
      }
    }
    return minuteKlines;
  }

  // 五日分时均线数据
  Future<ApiResult> fetchFiveDayKline(Map<String, dynamic> params) async {
    final url = klineUrlFinanceBaiduFiveDay(params['ShareCode'], params['ShareCode']);
    try {
      return await getJson(url);
    } catch (e) {
      rethrow;
    }
  }
}
