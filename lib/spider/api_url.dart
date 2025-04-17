// 抓取数据的类型
enum SpiderTopic { kline, klineMinute, klineFiveDay }

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
