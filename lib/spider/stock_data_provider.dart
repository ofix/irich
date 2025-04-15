import "package:irich/store/stock.dart";

abstract class StockDataProvider {
  String get providerName;
  Future<MinuteKline?> fetchMinuteKline(String shareCode); // 分时K线
  Future<UiKline?> fetchDailyKline(String shareCode); // 日K线
}

