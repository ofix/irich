// 腾讯财经行情页 K 线数据 URL 生成函数
String klineUrlTencent(
  String shareCode,
  String marketAbbr,
  String klineType,
  String year,
  String startTime,
  String endTime,
) {
  return "https://proxy.finance.qq.com/ifzqgtimg/appstock/app/newfqkline/"
      "get?_var=kline_${klineType}qfq$year&param=$marketAbbr$shareCode,$klineType,$startTime,"
      "$endTime,640,qfq";
}
