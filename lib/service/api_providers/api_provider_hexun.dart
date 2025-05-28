// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/api_providers/api_provider_hexun.dart
// Purpose:     he xun api provider
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

// ignore_for_file: avoid_print
import "dart:convert";

import "package:irich/service/api_provider_capabilities.dart";
import "package:irich/service/api_providers/api_provider.dart";
import "package:irich/global/stock.dart";
import "package:http/http.dart" as http;
import "package:irich/service/request_log.dart";

// 和讯网股票列表获取函数
String shareListUrlHexun(int market, int pageOffset, int pageSize) {
  return "https://stocksquote.hexun.com/a/sortlist"
      "?block=$market"
      "&title=15"
      "&direction=0"
      "&start=$pageOffset"
      "&number=$pageSize"
      "&column=code,name,price,updownrate,LastClose,open,high,low,volume,priceweight,amount,"
      "exchangeratio,VibrationRatio,VolumeRatio";
}

// 通过和讯财经获取股票数据
class ApiProviderHexun extends ApiProvider {
  @override
  final provider = EnumApiProvider.heXun;
  List<Share> marketShares = [];

  @override
  Future<dynamic> doRequest(
    ProviderApiType apiType,
    Map<String, dynamic> params, [
    void Function(RequestLog requestLog)? onPagerProgress,
  ]) async {
    switch (apiType) {
      case ProviderApiType.quote:
        return fetchQuote();
      default:
        throw Exception('Unsupported API type: $ProviderApiType');
    }
  }

  // 根据请求类型解析响应数据
  @override
  dynamic parseResponse(ProviderApiType apiType, dynamic response) {
    return response;
  }

  List<Share> removeDuplicates(List<Share> shares) {
    // 使用 Map 去重（保留最后一个出现的 Share）
    final uniqueMap = {for (var share in shares) share.code: share};
    return uniqueMap.values.toList();
  }

  // 获取股票列表
  Future<dynamic> fetchQuote() async {
    try {
      final List<int> markets = [1, 1, 1, 2, 2, 2, 6, 6, 1789];
      final results = await Future.wait([
        _fetchMarketShares(1, 0, 1000), // 沪市A股
        _fetchMarketShares(1, 1000, 1000), // 沪市A股
        _fetchMarketShares(1, 2000, 1000), // 沪市A股
        _fetchMarketShares(2, 0, 1000), // 深市A股
        _fetchMarketShares(2, 1000, 1000), // 深市A股
        _fetchMarketShares(2, 2000, 1000), // 深市A股
        _fetchMarketShares(6, 0, 1000), // 创业板
        _fetchMarketShares(6, 1000, 1000), // 创业板
        _fetchMarketShares(1789, 0, 1000), // 科创板
      ]);
      for (var i = 0; i < results.length; i++) {
        marketShares.addAll(_parseMarketShare(results[i], markets[i]));
      }
      // 股票去重
      marketShares = removeDuplicates(marketShares);
      return marketShares;
    } catch (e) {
      throw Exception('Failed to fetch market shares: $e');
    }
  }

  // 获取和讯网股票列表数据
  Future<dynamic> _fetchMarketShares(int market, int pageOffset, int pageSize) async {
    final url = shareListUrlHexun(market, pageOffset, pageSize);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = response.body.replaceAll(RegExp(r'^\(|\);$'), '');
      return data;
    } else {
      throw Exception('Failed to request market shares, $url');
    }
  }

  // 将市场类型转换为 Market 枚举
  Market _toMarket(int market) {
    final kv = {
      1: Market.shangHai,
      2: Market.shenZhen,
      6: Market.chuangYeBan,
      1789: Market.keChuangBan,
    };
    if (kv.containsKey(market)) {
      return kv[market]!;
    } else {
      throw ArgumentError('Invalid market value: $market');
    }
  }

  // 解析股票列表返回结果
  List<Share> _parseMarketShare(String response, int market) {
    List<Share> shares = [];
    try {
      final jsonData = jsonDecode(response);
      // final count = jsonData['Total'] as int;
      final arr = jsonData['Data'][0] as List;

      for (final item in arr) {
        final factor = item[9];
        final share = Share(
          code: item[0].toString(),
          name: (item[1] as String).replaceAll(' ', ''),
          market: _toMarket(market),
          priceYesterdayClose: item[4] / factor,
          priceNow: item[2] / factor,
          changeRate: item[3] / 10000,
          priceOpen: item[5] / factor,
          priceMax: item[6] / factor,
          priceMin: item[7] / factor,
          volume: (item[8] / 100).toInt(),
          amount: ((item[10] as num).toDouble()),
          turnoverRate: item[11] / 10000,
          priceAmplitude: item[12] / 10000,
          qrr: item[13] / 100,
        );

        shares.add(share);
      }
      return shares;
    } catch (e) {
      throw Exception('Failed to parse stock data: $e');
    }
  }
}
