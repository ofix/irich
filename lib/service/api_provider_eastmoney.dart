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
      case EnumApiType.sideMenu:
        return fetchSideMenu(params);
      case EnumApiType.industry:
        return fetchIndustry(params);
      case EnumApiType.concept:
        return fetchConcept(params);
      case EnumApiType.province:
        return fetchProvince(params);
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
      case EnumApiType.sideMenu:
        return parseSideMenu(response); // 侧边栏数据
      case EnumApiType.industry:
        return parseIndustry(response); // 行业数据
      case EnumApiType.concept:
        return parseConcept(response); // 概念数据
      case EnumApiType.province:
        return parseProvince(response); // 省份数据
      case EnumApiType.dayKline:
        return parseDayKline(response); // 日K线数据
      case EnumApiType.fiveDayKline:
        return parseFiveDayKline(response); // 5日K线分时数据
      case EnumApiType.minuteKline:
        return parseMinuteKline(response); // 分时K线数据
      default:
        throw UnimplementedError('Unsupported API type: $enumApiType');
    }
  }

  // 获取侧边栏数据
  Future<dynamic> fetchSideMenu(Map<String, dynamic> params) async {
    final url = " https://quote.eastmoney.com/center/api/sidemenu_new.json";
    try {
      return asyncRequest(url);
    } catch (e) {
      rethrow;
    }
  }

  List<List<String>> parseSideMenu(String response) {
    final List<String> concepts = [];
    final List<String> industries = [];
    final List<String> provinces = [];
    final List<List<String>> menu = [];
    // 解析JSON数据
    final dynamic result = jsonDecode(response);
    final List<dynamic> bklist = result["bklist"]; // 行业/概念/地域板块列表
    for (final bk in bklist) {
      final int type = bk["type"];
      if (type == 1) {
        provinces.add(bk["name"]); // 地域板块
      } else if (type == 2) {
        industries.add(bk["name"]); // 行业板块
      } else if (type == 3) {
        concepts.add(bk["name"]); // 概念板块
      }
    }
    menu.addAll([provinces, industries, concepts]);
    return menu;
  }

  Future<dynamic> fetchConcept(Map<String, dynamic> params) async {
    return fetchBk(params);
  }

  Future<dynamic> fetchIndustry(Map<String, dynamic> params) async {
    return fetchBk(params);
  }

  Future<dynamic> fetchProvince(Map<String, dynamic> params) async {
    return fetchBk(params);
  }

  Future<dynamic> fetchBk(Map<String, dynamic> params) async {
    final name = params['name'];
    final url =
        "https://push2delay.eastmoney.com/api/qt/clist/get?pn=1&pz=10000&po=1&np=1&fltt=1&invt=2&dect=1&fid=f3&fs=b:$name&fields=f3,f12,f14";
    try {
      return asyncRequest(url);
    } catch (e) {
      rethrow;
    }
  }

  List<String> parseConcept(String response) {
    final List<String> concept = [];
    // 解析JSON数据
    final dynamic result = jsonDecode(response);
    final List<dynamic> data = result["data"]['diff'];
    for (final row in data) {
      final String shareCode = row["f12"];
      final String shareName = row['f14'];
    }
    return concept;
  }

  List<String> parseProvince(String response) {
    final List<String> province = [];
    // 解析JSON数据
    final dynamic result = jsonDecode(response);
    final List<dynamic> data = result["data"];
    for (final row in data) {
      final String name = row["name"];
      province.add(name);
    }
    return province;
  }

  List<String> parseIndustry(String response) {
    final List<String> industry = [];
    // 解析JSON数据
    final dynamic result = jsonDecode(response);
    final List<dynamic> data = result["data"];
    for (final row in data) {
      final String name = row["name"];
      industry.add(name);
    }
    return industry;
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
