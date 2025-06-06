import 'package:flutter/material.dart';

class StockColors extends ThemeExtension<StockColors> {
  final Color klineUp; // 红柱颜色
  final Color klineDown; // 绿柱颜色
  final Color macdDif; // MACD dif 颜色
  final Color macdDea; // MACD dea 信号线颜色
  final Color macdRedBar; // MACD 红柱颜色
  final Color macdGreenBar; // MACD 绿柱颜色
  final Color kdjK; // KDJ K 颜色
  final Color kdjD; // KDJ D 颜色
  final Color kdjJ; // KDJ J 颜色
  final Color ma5;
  final Color ma10;
  final Color ma20;
  final Color ma30;
  final Color crossLine;

  const StockColors({
    required this.klineUp,
    required this.klineDown,
    required this.macdDif,
    required this.macdDea,
    required this.macdRedBar,
    required this.macdGreenBar,
    required this.kdjK,
    required this.kdjD,
    required this.kdjJ,
    required this.ma5,
    required this.ma10,
    required this.ma20,
    required this.ma30,
    required this.crossLine,
  });

  factory StockColors.light() {
    return StockColors(
      klineUp: Colors.red,
      klineDown: const Color.fromARGB(255, 84, 252, 252),
      macdDif: Colors.white,
      macdDea: Colors.yellow,
      macdRedBar: Colors.red,
      macdGreenBar: const Color.fromARGB(255, 84, 240, 89),
      kdjK: Colors.blue,
      kdjD: Colors.yellow,
      kdjJ: const Color.fromARGB(255, 255, 59, 203),
      crossLine: Colors.grey,
      ma5: Colors.pink,
      ma10: Colors.yellow.shade700,
      ma20: Colors.purple,
      ma30: Colors.orange,
    );
  }

  factory StockColors.dark() {
    return StockColors(
      klineUp: Colors.red,
      klineDown: const Color.fromARGB(255, 84, 252, 252),
      macdDif: Colors.white,
      macdDea: Colors.yellow,
      macdRedBar: Colors.red,
      macdGreenBar: const Color.fromARGB(255, 84, 240, 89),
      kdjK: Colors.blue,
      kdjD: Colors.yellow,
      kdjJ: const Color.fromARGB(255, 255, 59, 203),
      crossLine: Colors.white,
      ma5: Colors.pink.shade200,
      ma10: Colors.yellow.shade600,
      ma20: Colors.purple.shade200,
      ma30: Colors.orange.shade300,
    );
  }

  @override
  StockColors copyWith({
    Color? klineUp,
    Color? klineDown,
    Color? klineBorderUp,
    Color? klineBorderDown,
    Color? klineTextUp,
    Color? klineTextDown,
    Color? volumeUp,
    Color? volumeDown,
    Color? macdDif,
    Color? macdDea,
    Color? macdRedBar,
    Color? macdGreenBar,
    Color? kdjK,
    Color? kdjD,
    Color? kdjJ,
    Color? ma5,
    Color? ma10,
    Color? ma20,
    Color? ma30,
    Color? crossLine,
    Color? verticalLine,
  }) {
    return StockColors(
      klineUp: klineUp ?? this.klineUp,
      klineDown: klineDown ?? this.klineDown,
      macdDif: macdDif ?? this.macdDif,
      macdDea: macdDea ?? this.macdDea,
      macdRedBar: macdRedBar ?? this.macdRedBar,
      macdGreenBar: macdGreenBar ?? this.macdGreenBar,
      kdjK: kdjK ?? this.kdjK,
      kdjD: kdjD ?? this.kdjD,
      kdjJ: kdjJ ?? this.kdjJ,
      ma5: ma5 ?? this.ma5,
      ma10: ma10 ?? this.ma10,
      ma20: ma20 ?? this.ma20,
      ma30: ma30 ?? this.ma30,
      crossLine: crossLine ?? this.crossLine,
    );
  }

  @override
  StockColors lerp(ThemeExtension<StockColors>? other, double t) {
    if (other is! StockColors) return this;
    return StockColors(
      klineUp: Color.lerp(klineUp, other.klineUp, t)!,
      klineDown: Color.lerp(klineDown, other.klineDown, t)!,
      macdDif: Color.lerp(macdDif, other.macdDif, t)!,
      macdDea: Color.lerp(macdDea, other.macdDea, t)!,
      macdRedBar: Color.lerp(macdRedBar, other.macdRedBar, t)!,
      macdGreenBar: Color.lerp(macdGreenBar, other.macdGreenBar, t)!,
      kdjK: Color.lerp(kdjK, other.kdjK, t)!,
      kdjD: Color.lerp(kdjD, other.kdjD, t)!,
      kdjJ: Color.lerp(kdjJ, other.kdjJ, t)!,
      ma5: Color.lerp(ma5, other.ma5, t)!,
      ma10: Color.lerp(ma10, other.ma10, t)!,
      ma20: Color.lerp(ma20, other.ma20, t)!,
      ma30: Color.lerp(ma30, other.ma30, t)!,
      crossLine: Color.lerp(crossLine, other.crossLine, t)!,
    );
  }
}
