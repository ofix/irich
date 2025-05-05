import 'package:irich/formula/formula.dart';
import 'package:irich/global/stock.dart';

class FormulaEma extends Formula {
  FormulaEma() : super(FormulaType.ema);

  /// 计算EMA指标
  /// [klines] K线数据列表
  /// [period] EMA周期
  /// 返回EMA值列表
  static List<double> calculateEma(List<UiKline> klines, int period) {
    final emaPrices = <double>[];
    if (klines.isEmpty || period <= 0) return emaPrices;

    // 初始化EMA为第一个收盘价
    double emaPrice = klines.first.priceClose;
    final multiplier = 2.0 / (period + 1); // 计算平滑因子
    emaPrices.add(emaPrice);

    for (int i = 1; i < klines.length; i++) {
      // 计算EMA: (当前收盘价 - 前一日EMA) * 平滑因子 + 前一日EMA
      emaPrice = (klines[i].priceClose - emaPrice) * multiplier + emaPrice;
      emaPrices.add(emaPrice);
    }

    return emaPrices;
  }
}
