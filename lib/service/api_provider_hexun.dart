// ignore_for_file: avoid_print
import "dart:convert";

import "package:irich/service/api_provider_capabilities.dart";
import "package:irich/service/api_provider.dart";
import "package:irich/types/stock.dart";
import "package:http/http.dart" as http;

// 和讯网股票列表获取函数
String shareListUrlHexun(int market) {
  return "https://stocksquote.hexun.com/a/sortlist"
      "?block=$market"
      "&title=15"
      "&direction=0"
      "&start=0"
      "&number=10000"
      "&column=code,name,price,updownrate,LastClose,open,high,low,volume,priceweight,amount,"
      "exchangeratio,VibrationRatio,VolumeRatio";
}

// 通过和讯财经获取股票数据
class ApiProviderHexun extends ApiProvider {
  @override
  final name = EnumApiProvider.heXun;
  List<Share> marketShares = [];

  @override
  Future<dynamic> doRequest(EnumApiType enumApiType, Map<String, dynamic> params) async {
    switch (enumApiType) {
      case EnumApiType.quote:
        return fetchQuote();
      default:
        throw Exception('Unsupported API type: $enumApiType');
    }
  }

  // 根据请求类型解析响应数据
  @override
  dynamic parseResponse(EnumApiType enumApiType, dynamic response) {
    return response;
  }

  // 获取股票列表
  Future<dynamic> fetchQuote() async {
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
      return marketShares;
    } catch (e) {
      throw Exception('Failed to fetch market shares: $e');
    }
  }

  // 获取和讯网股票列表数据
  Future<dynamic> _fetchMarketShares(int market) async {
    final url = shareListUrlHexun(market);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = response.body.replaceAll(RegExp(r'^\(|\);$'), '');
      return data;
    } else {
      throw Exception('Failed to request market shares');
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
          volume: ((item[8].toDouble() / 100) as double).toInt(),
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
