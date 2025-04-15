import "package:irich/spider/stock_data_provider.dart";
import "package:irich/store/stock.dart";

// 2. 实现具体数据源（示例：东方财富）
class StockDataProviderEastMoney implements StockDataProvider {
  @override
  final String providerName = 'east_money';

  @override
  Future<MinuteKline?> fetchMinuteKline(String shareCode) async {
    // 分时K线
    Uri.https('datacenter-web.eastmoney.com', '/api/data/v1/get', {
      'reportName': 'RPT_KLINE',
      'stockCode': shareCode,
      'pageSize': '1000',
    });
    // 实现具体请求逻辑...
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
