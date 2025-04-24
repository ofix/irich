// ignore_for_file: avoid_print
import "package:irich/service/api_provider.dart";
import "package:irich/service/api_provider_capabilities.dart";
import "package:irich/service/api_url.dart";

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
class ApiProviderBaidu implements ApiProvider {
  @override
  final name = EnumApiProvider.baiduFinance;

  @override
  Future<dynamic> doRequest(
    EnumApiType enumApiType,
    Map<String, dynamic> params,
  ) async {
    switch (enumApiType) {
      case EnumApiType.dayKline:
        return fetchDayKline(params);
      case EnumApiType.minuteKline:
        return fetchMinuteKline(params);
      case EnumApiType.fiveDayKline:
        return fetchFiveDayKline(params);
      default:
        throw UnimplementedError('Unsupported API type: $enumApiType');
    }
  }

  // 分时K线
  Future<dynamic> fetchMinuteKline(Map<String, dynamic> params) async {
    final url = klineUrlFinanceBaiduMinute(params['shareCode']);
    try {
      return await asyncRequest(url);
    } catch (e) {
      rethrow;
    }
  }

  // 五日分时均线数据
  Future<dynamic> fetchFiveDayKline(Map<String, dynamic> params) async {
    final url = klineUrlFinanceBaiduFiveDay(
      params['shareCode'],
      params['shareCode'],
    );
    try {
      return await asyncRequest(url);
    } catch (e) {
      rethrow;
    }
  }

  // 日K线数据
  Future<dynamic> fetchDayKline(Map<String, dynamic> params) async {
    final url = klineUrlFinanceBaidu(
      params['shareCode'],
      "day", // 日K线
      "",
    );
    try {
      return await asyncRequest(url);
    } catch (e) {
      rethrow;
    }
  }

  // 根据请求类型解析响应数据
  @override
  void parseResponse(EnumApiType enumApiType, dynamic response) {}
}
