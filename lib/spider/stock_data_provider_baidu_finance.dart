import "package:irich/spider/stock_data_provider.dart";
import "package:irich/store/stock.dart";

// 3. 实现百度财经数据源（支持分页）
class StockDataProviderBaiduFinance implements StockDataProvider {
  @override
  final String providerName = 'baidu_finance';

  @override
  Future<MinuteKline?> fetchMinuteKline(String shareCode) async {
    // 分时K线
    return null;
  }
    @override
  Future<UiKline?> fetchDailyKline(String shareCode) async {
    // 分时K线
    Uri.https('datacenter-web.eastmoney.com', '/api/data/v1/get', {
      'reportName': 'RPT_KLINE',
      'stockCode': shareCode,
      'pageSize': '1000',
    });
    // 实现具体请求逻辑...
    return null;
  }
}