// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/api_providers/api_provider_sina.dart
// Purpose:     sina api provider
// Author:      songhuabiao
// Created:     2025-08-18 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

// ignore_for_file: avoid_print
import "dart:convert";

import "package:flutter/cupertino.dart";
import "package:irich/service/api_provider_capabilities.dart";
import "package:irich/service/api_providers/api_provider.dart";
import "package:irich/global/stock.dart";
import "package:http/http.dart" as http;
import "package:irich/service/request_log.dart";

// 和讯网股票列表获取函数
String shareListUrlSina(String market, int pageOffset, int pageSize) {
  return "https://vip.stock.finance.sina.com.cn/quotes_service/api/json_v2.php/Market_Center.getHQNodeData"
      "?page=$pageOffset"
      "&num=$pageSize"
      "&sort=changepercent"
      "&asc=0"
      "&node=$market"
      "&symbol=";
}

// 通过和讯财经获取股票数据
class ApiProviderSina extends ApiProvider {
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
      final markets = ['sh_a', 'sz_a']; // 沪市A股和深市A股
      final counts = await Future.wait([
        fetchMarketShareCount(markets[0]), // 沪市A股
        fetchMarketShareCount(markets[1]), // 深市A股(主板+创业板)
      ]);
      for (var i = 0; i < markets.length; i++) {
        debugPrint('market ${markets[i]} share count: ${counts[i]}');
      }
      final results = await Future.wait([
        _fetchMarketShares('sh_a', counts[0]), // 沪市A股
        _fetchMarketShares('sz_a', counts[1]), // 深市A股
      ]);
      for (var i = 0; i < results.length; i++) {
        marketShares.addAll(results[i]);
      }
      return marketShares;
    } catch (e) {
      throw Exception('Failed to fetch market shares: $e');
    }
  }

  // 获取交易所股票个数
  Future<int> fetchMarketShareCount(String market) async {
    try {
      final url =
          "https://vip.stock.finance.sina.com.cn/quotes_service/api/json_v2.php/Market_Center.getHQNodeStockCount?node=$market";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = response.body;
        String count = data.trim().replaceAll(RegExp(r'[^0-9]'), '');
        final shareCount = int.parse(count);
        return shareCount;
      } else {
        throw Exception('Failed to request market shares count, $url');
      }
    } catch (e) {
      throw Exception('Failed to fetch market share count: $e');
    }
  }

  // 获取和讯网股票列表数据
  Future<List<Share>> _fetchMarketShares(String market, int count) async {
    final List<Share> shares = [];
    int pageOffset = 1;
    int pageSize = 100; // 每页大小
    try {
      while (pageOffset * pageSize <= count) {
        final url = shareListUrlSina(market, pageOffset, pageSize);
        debugPrint("[行情][新浪]: $url");
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final sharesInPage = _parseMarketShare(response.body, market);
          shares.addAll(sharesInPage);
        }
        if (shares.length == count) break;
        pageOffset++;
      }
      return shares;
    } catch (e) {
      debugPrint("分页获取新浪财经股票列表失败: $e");
      rethrow;
    }
  }

  // 将市场类型转换为 Market 枚举
  Market _toMarket(String market) {
    final kv = {"sh_a": Market.shangHai, "sz_a": Market.shenZhen};
    if (kv.containsKey(market)) {
      return kv[market]!;
    } else {
      throw ArgumentError('Invalid market value: $market');
    }
  }

  // 解析股票列表返回结果
  List<Share> _parseMarketShare(String response, String market) {
    List<Share> shares = [];
    String code = "";
    try {
      final arr = jsonDecode(response) as List<dynamic>;
      for (final json in arr) {
        final item = json as Map<String, dynamic>;
        final share = Share(
          code: item['code'] as String,
          name: item['name'] as String,
          market: _toMarket(market),
          priceYesterdayClose: double.tryParse((item['settlement'] ?? "")) ?? 0.0,
          priceNow: double.tryParse((item['buy'] ?? "")) ?? 0.0,
          changeRate: (item['changepercent'] as num).toDouble(),
          priceOpen: double.tryParse((item['open'] ?? "")) ?? 0.0,
          priceMax: double.tryParse((item['high'] ?? "")) ?? 0.0,
          priceMin: double.tryParse((item['low'] ?? "")) ?? 0.0,
          volume: item['volume'] as int,
          amount: (item['amount'] as num).toDouble(),
          turnoverRate: (item['turnoverratio'] as num).toDouble(),
          priceAmplitude: (item['pricechange'] as num).toDouble(),
          qrr: 0.0,
        );
        code = item['code'] as String;
        shares.add(share);
      }
      return shares;
    } catch (e) {
      throw Exception('Failed to parse stock data: $e, code : $code,response: $response');
    }
  }
}
