// ignore_for_file: avoid_print
import "dart:convert";
import "package:irich/service/api_provider_capabilities.dart";
import "package:irich/service/api_provider.dart";
import "package:irich/types/stock.dart";

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
  final name = EnumApiProvider.eastMoney;

  @override
  Future<dynamic> doRequest(
    EnumApiType enumApiType,
    Map<String, dynamic> params,
  ) async {
    switch (enumApiType) {
      case EnumApiType.dayKline:
        return fetchDayKline(params);
      case EnumApiType.fiveDayKline:
        return fetchFiveDayKline(params);
      case EnumApiType.minuteKline:
        return fetchMinuteKline(params);
      default:
        throw UnimplementedError('Unsupported API type: $enumApiType');
    }
  }

  // 根据请求类型解析响应数据
  @override
  dynamic parseResponse(EnumApiType enumApiType, dynamic response) {
    switch (enumApiType) {
      case EnumApiType.dayKline:
        return parseDayKline(response);
      case EnumApiType.fiveDayKline:
        return parseFiveDayKline(response);
      case EnumApiType.minuteKline:
        return parseMinuteKline(response);
      default:
        throw UnimplementedError('Unsupported API type: $enumApiType');
    }
  }

  // 获取分时K线数据
  Future<dynamic> fetchMinuteKline(Map<String, dynamic> params) async {
    final url = klineUrlEastMoneyMinute(params['shareCode'], 3);
    try {
      return asyncRequest(url);
    } catch (e) {
      rethrow;
    }
  }

  // 获取五日分时数据
  Future<dynamic> fetchFiveDayKline(Map<String, dynamic> params) async {
    // 日K线
    final url = klineUrlEastMoneyFiveDay(params['shareCode'], 0);
    try {
      return asyncRequest(url);
    } catch (e) {
      rethrow;
    }
  }

  // 获取日K线数据
  Future<dynamic> fetchDayKline(Map<String, dynamic> params) async {
    // 日K线
    final url = klineUrlEastMoney(params['shareCode'], 0, 1);
    try {
      return asyncRequest(url);
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

  // 解析分时K线数据
  List<MinuteKline?> parseMinuteKline(String response) {
    final minuteKlines = <MinuteKline>[];
    // 解析JSON数据
    final result = jsonDecode(response);
    final data = result["data"]["trends"] as String;
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

  List<UiKline> parseFiveDayKline(String response) {
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
}
