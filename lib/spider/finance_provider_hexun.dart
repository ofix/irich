// ignore_for_file: avoid_print
import "dart:convert";

import "package:irich/spider/api_url.dart";
import "package:irich/spider/finance_provider.dart";
import "package:irich/store/stock.dart";
import "package:http/http.dart" as http;

// 通过和讯财经获取股票数据
class FinanceProviderHexun implements FinanceProvider {
  @override
  final String providerName = 'Hexun';
  List<Share> marketShares = [];

  // 获取股票列表
  void getMarketShares() async {
    try {
      final List<int> markets = [1, 2, 6, 1789];
      final results = await Future.wait([
        _fetchMarketShares(1), // 沪市A股
        _fetchMarketShares(2), // 深市A股
        _fetchMarketShares(6), // 创业板
        _fetchMarketShares(1789), // 科创板
      ]);
      for (var i = 0; i < results.length; i++) {
        marketShares.addAll(_parseMarketShare(results[i], markets[i]));
      }
    } catch (e) {
      throw Exception('Failed to fetch market shares: $e');
    }
  }

  // 获取和讯网股票列表数据
  Future<String> _fetchMarketShares(int market) async {
    final url = shareListUrlHexun(market);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to request market shares');
    }
  }
  // 将市场类型转换为 Market 枚举
  Market _toMarket(int market){
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
    // 正则替换
    response = response
        .replaceAll(RegExp(r'$'), '')
        .replaceAll(RegExp(r'$;'), '');
    try {
      final jsonData = jsonDecode(response);
      // final count = jsonData['Total'] as int;
      final arr = jsonData['Data'][0] as List;

      for (final item in arr) {
        final factor = item[9].toDouble();
        final share = Share(
          code: item[0].toString(),
          name: (item[1] as String).replaceAll(' ', ''),
          market: _toMarket(market),
          priceYesterdayClose: item[4].toDouble() / factor,
          priceNow: item[2].toDouble() / factor,
          changeRate: item[3].toDouble() / 100,
          priceOpen: item[5].toDouble() / factor,
          priceMax: item[6].toDouble() / factor,
          priceMin: item[7].toDouble() / factor,
          volume: item[8].toDouble() / 100,
          amount: item[10].toDouble(),
          turnoverRate: item[11].toDouble() / 100,
          priceAmplitude: item[12].toDouble() / 100,
          qrr: item[13].toDouble() / 100,
        );

        shares.add(share);
      }
      return shares;
    } catch (e) {
      throw Exception('Failed to parse stock data: $e');
    }
  }
}
