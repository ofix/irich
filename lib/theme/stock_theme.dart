import 'package:flutter/material.dart';
import 'stock_colors.dart';

extension StockTheme on BuildContext {
  StockColors get stockColors => Theme.of(this).extension<StockColors>()!;
  Color get klineUpColor => stockColors.klineUp;
  Color get klineDownColor => stockColors.klineDown;
  Color get macdDifColor => stockColors.macdDif;
  Color get macdDeaColor => stockColors.macdDea;
  Color get ma5Color => stockColors.ma5;
  Color get ma10Color => stockColors.ma10;
  Color get ma20Color => stockColors.ma20;
  Color get ma30Color => stockColors.ma30;
}

class StockColorUtils {
  static Color getColorByDirection(BuildContext context, bool isUp) {
    return isUp ? context.klineUpColor : context.klineDownColor;
  }

  static Color getMaColor(BuildContext context, int days) {
    final colors = context.stockColors;
    switch (days) {
      case 5:
        return colors.ma5;
      case 10:
        return colors.ma10;
      case 20:
        return colors.ma20;
      case 30:
        return colors.ma30;
      default:
        return colors.ma5;
    }
  }
}
