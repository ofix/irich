import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/store/components/state_kline.dart';
import 'package:irich/types/stock.dart';
import 'dart:math';

class KlineChart extends ConsumerStatefulWidget {
  final String shareCode;

  const KlineChart({super.key, required this.shareCode});

  @override
  ConsumerState<KlineChart> createState() => _KlineChartState();
}

class _KlineChartState extends ConsumerState<KlineChart> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(klineProvider.notifier).loadKlines(widget.shareCode, KlineType.day);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(klineProvider);
    final notifier = ref.read(klineProvider.notifier);

    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onTapDown: _handleTap,
      child: Container(
        color: const Color(0xFF1E1E1E),
        padding: const EdgeInsets.only(left: 48, right: 48, top: 16, bottom: 16), // 背景色
        child: CustomPaint(
          size: Size.infinite,
          painter: _KlinePainter(state: state, notifier: notifier),
        ),
      ),
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {}

  void _handleTap(TapDownDetails details) {
    final state = ref.read(klineProvider);
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // 计算点击的K线索引
    final index = (localPosition.dx / state.klineWidth).floor();
    ref.read(klineProvider.notifier).moveCrossLine(index);
  }
}

class _KlinePainter extends CustomPainter {
  final KlineState state;
  final KlineNotifier notifier;
  _KlinePainter({required this.state, required this.notifier});

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景
    _drawBackground(canvas, size);

    // 根据不同类型绘制K线
    switch (state.type) {
      case KlineType.minute:
        _drawMinuteKlines(canvas, size);
        break;
      case KlineType.fiveDay:
        _drawFiveDayMinuteKlines(canvas, size);
        break;
      default:
        _drawDayKlines(canvas, size);
    }

    // 绘制十字线
    if (state.crossLineIndex != -1) {
      _drawCrossLine(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint =
        Paint()
          ..color = const Color(0xFF1E1E1E)
          ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 绘制网格线
    final gridPaint =
        Paint()
          ..color = const Color(0xFF333333)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    // 水平网格线
    const horizontalLines = 8;
    final hStep = size.height / horizontalLines;
    for (var i = 0; i <= horizontalLines; i++) {
      final y = i * hStep;
      canvas.drawLine(Offset(0, y), Offset(0 + size.width, y), gridPaint);
    }
    notifier.getRectMaxPrice(state.klines, state.klineRng.begin, state.klineRng.end);
    // 垂直网格线
    const verticalLines = 6;
    final vStep = size.width / verticalLines;
    for (var i = 0; i <= verticalLines; i++) {
      final x = i * vStep;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  void _drawDayKlines(Canvas canvas, Size size) {
    if (state.klines.isEmpty) return;
    notifier.getRectMaxPrice(state.klines, state.klineRng.begin, state.klineRng.end);
    notifier.getRectMinPrice(state.klines, state.klineRng.begin, state.klineRng.end);

    final priceRange = state.maxRectPrice - state.minRectPrice;
    final priceRatio = size.height / priceRange;

    final maxPrice = state.maxRectPrice;

    // 绘制K线
    for (var i = state.klineRng.begin; i < state.klineRng.end; i++) {
      final kline = state.klines[i];
      final x = i * state.klineWidth;
      final centerX = x + state.klineInnerWidth / 2;

      // 计算坐标
      final highY = (maxPrice - kline.priceMax) * priceRatio;
      final lowY = (maxPrice - kline.priceMin) * priceRatio;
      final openY = (maxPrice - kline.priceOpen) * priceRatio;
      final closeY = (maxPrice - kline.priceClose) * priceRatio;

      // 决定颜色
      final isUp = kline.priceClose > kline.priceOpen;
      final color =
          isUp
              ? Colors.red
              : kline.priceClose == kline.priceOpen
              ? Colors.grey
              : Colors.green;

      // 绘制上下影线
      final shadowPaint =
          Paint()
            ..color = color
            ..strokeWidth = 1;
      // 绘制日K线上影线
      canvas.drawLine(Offset(centerX, highY), Offset(centerX, isUp ? closeY : openY), shadowPaint);
      // 绘制日K线下影线
      canvas.drawLine(Offset(centerX, isUp ? openY : closeY), Offset(centerX, lowY), shadowPaint);

      // 绘制日K线实体
      final klinePaint =
          Paint()
            ..color = color
            ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTRB(x, isUp ? closeY : openY, x + state.klineInnerWidth, isUp ? openY : closeY),
        klinePaint,
      );
    }

    // 绘制EMA曲线
    for (final ema in state.emaCurves) {
      if (ema.visible) {
        _drawEmaCurve(canvas, ema, size, maxPrice, priceRatio);
      }
    }
  }

  void _drawEmaCurve(
    Canvas canvas,
    ShareEmaCurve ema,
    Size size,
    double maxPrice,
    double priceRatio,
  ) {
    // 少于2条K线数据无法绘制EMA曲线
    if (state.klines.length <= 2) return;
    final path = Path();
    final paint =
        Paint()
          ..color = ema.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
    for (int i = state.klineRng.begin; i <= state.klineRng.end; i++) {
      final x = i * state.klineWidth;
      final y = (maxPrice - ema.emaPrice[i]) * priceRatio;

      if (i == state.klineRng.begin) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawMinuteKlines(Canvas canvas, Size size) {
    if (state.minuteKlines.isEmpty) return;

    // 计算价格范围
    var minPrice = double.infinity;
    var maxPrice = -double.infinity;

    for (final kline in state.minuteKlines) {
      if (kline.price < minPrice) minPrice = kline.price;
      if (kline.price > maxPrice) maxPrice = kline.price;
    }

    final priceRange = maxPrice - minPrice;
    final priceRatio = size.height / priceRange;

    // 绘制分时线
    final path = Path();
    final paint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    for (var i = 0; i < state.minuteKlines.length; i++) {
      final kline = state.minuteKlines[i];
      final x = i * (size.width / 240);
      final y = (maxPrice - kline.price) * priceRatio;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // 绘制均线
    final avgPath = Path();
    final avgPaint =
        Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    for (var i = 0; i < state.minuteKlines.length; i++) {
      final kline = state.minuteKlines[i];
      final x = i * (size.width / 240);
      final y = (maxPrice - kline.avgPrice) * priceRatio;

      if (i == 0) {
        avgPath.moveTo(x, y);
      } else {
        avgPath.lineTo(x, y);
      }
    }

    canvas.drawPath(avgPath, avgPaint);
  }

  void _drawFiveDayMinuteKlineBackground(Canvas canvas, double refClosePrice, double deltaPrice) {
    const nRows = 16;
    const nCols = 20;
    final wRect = state.width;
    double hRect = 2000;
    final hRow = (hRect - (nRows + 2)) / nRows;
    final wCol = wRect / nCols;
    final dwCol = wRect / 5;

    // Define pens (paints)
    final solidPen =
        Paint()
          ..color = const Color(0xFF555555) // KLINE_PANEL_BORDER_COLOR
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    final solidPen2 =
        Paint()
          ..color = const Color(0xFF555555)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final dotPen =
        Paint()
          ..color = const Color(0xFF555555)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    // Calculate prices and amplitudes
    final prices = <double>[];
    final amplitudes = <double>[];
    final rowPrice = deltaPrice * 2 / nRows;

    if (rowPrice < 0.01) {
      for (var i = 0; i < 8; i++) {
        prices.add(refClosePrice + 0.01 * (i + 1));
        amplitudes.add((prices[i] / refClosePrice - 1) * 100);
      }
      for (var i = 0; i < 8; i++) {
        prices.add(refClosePrice - 0.01 * (i + 1));
        amplitudes.add((1 - prices[i] / refClosePrice) * 100);
      }
    } else {
      for (var i = 0; i < 8; i++) {
        prices.add(refClosePrice + rowPrice * (i + 1));
        amplitudes.add((prices[i] / refClosePrice - 1) * 100);
      }
      for (var i = 0; i < 8; i++) {
        prices.add(refClosePrice - rowPrice * (i + 1));
        amplitudes.add(amplitudes[i]);
      }
    }

    double offsetX = 0;

    // Draw outer borders
    // Top border
    canvas.drawLine(Offset(offsetX, 0), Offset(offsetX + wRect, 0), solidPen);
    // Bottom border
    canvas.drawLine(Offset(offsetX, hRect), Offset(offsetX + wRect, hRect), solidPen);
    // Left border
    canvas.drawLine(Offset(offsetX, 0), Offset(offsetX, hRect), solidPen);
    // Right border
    canvas.drawLine(Offset(offsetX + wRect, 0), Offset(offsetX + wRect, hRect), solidPen);

    // Draw center horizontal line (thick)
    canvas.drawLine(Offset(offsetX, hRect / 2), Offset(offsetX + wRect, hRect / 2), solidPen2);

    // Draw 5-day vertical dividers (thick)
    final nDay = nCols ~/ 4;
    for (var i = 1; i <= nDay; i++) {
      final x = offsetX + dwCol * i;
      canvas.drawLine(Offset(x, 0), Offset(x, hRect), solidPen2);
    }

    // Draw daily vertical dividers (dotted)
    for (var i = 1; i < nCols; i++) {
      final x = offsetX + wCol * i;
      if (i % 4 != 0) {
        // Draw dotted line
        final path = Path();
        path.moveTo(x, 0);
        path.lineTo(x, hRect);
        canvas.drawPath(path, dotPen);
      }
    }

    // Draw horizontal dotted lines
    for (var i = 1; i <= nRows; i++) {
      final y = (hRow + 1) * i;
      if (i == 8 || i == 16) continue; // Skip solid lines

      // Draw dotted line
      final path = Path();
      path.moveTo(offsetX, y);
      path.lineTo(offsetX + wRect, y);
      canvas.drawPath(path, dotPen);
    }

    // Prepare text painter
    final textStyle = TextStyle(color: Colors.white, fontSize: 10);
    final textPainter = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.right);

    // Draw prices and amplitudes on left and right sides
    // Upper part (red)
    for (var i = 0; i < 8; i++) {
      final priceText = prices[8 - i - 1].toStringAsFixed(2);
      final amplitudeText = '${amplitudes[8 - i - 1].toStringAsFixed(2)}%';
      final y = (hRow + 1) * i + hRow / 2;

      // Left side price (red)
      textPainter.text = TextSpan(text: priceText, style: textStyle.copyWith(color: Colors.red));
      textPainter.layout();
      textPainter.paint(canvas, Offset(offsetX - 4, y - textPainter.height / 2));

      // Right side amplitude (red)
      textPainter.text = TextSpan(
        text: amplitudeText,
        style: textStyle.copyWith(color: Colors.red),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(offsetX + wRect + 4, y - textPainter.height / 2));
    }

    // Middle reference price (white)
    final middleY = (hRow + 1) * 8 - hRow / 2;
    textPainter.text = TextSpan(text: refClosePrice.toStringAsFixed(2), style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(offsetX - 4, middleY - textPainter.height / 2));

    textPainter.text = TextSpan(text: '0.00%', style: textStyle);
    textPainter.layout();
    textPainter.paint(canvas, Offset(offsetX + wRect + 4, middleY - textPainter.height / 2));

    // Lower part (green)
    for (var i = 8; i < 16; i++) {
      final priceText = prices[i].toStringAsFixed(2);
      final amplitudeText = '${amplitudes[i].toStringAsFixed}%';
      final y = (hRow + 1) * i + hRow / 2;

      // Left side price (green)
      textPainter.text = TextSpan(text: priceText, style: textStyle.copyWith(color: Colors.green));
      textPainter.layout();
      textPainter.paint(canvas, Offset(offsetX - 4, y - textPainter.height / 2));

      // Right side amplitude (green)
      textPainter.text = TextSpan(
        text: amplitudeText,
        style: textStyle.copyWith(color: Colors.green),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(offsetX + wRect + 4, y - textPainter.height / 2));
    }
  }

  // 绘制五日分时图
  void _drawFiveDayMinuteKlines(Canvas canvas, Size size) {
    // final nKlines = state.fiveDayMinuteKlines.length;
    double maxMinutePrice = double.negativeInfinity;
    double minMinutePrice = double.infinity;

    for (final kline in state.fiveDayMinuteKlines) {
      if (kline.price > maxMinutePrice) maxMinutePrice = kline.price;
      if (kline.price < minMinutePrice) minMinutePrice = kline.price;
    }

    final refClosePrice =
        state.fiveDayMinuteKlines.first.price - state.fiveDayMinuteKlines.first.changeAmount;

    // 计算最大波动幅度

    double maxDelta = max(
      (maxMinutePrice - refClosePrice).abs(),
      (minMinutePrice - refClosePrice).abs(),
    );

    if (maxDelta < 0.08) {
      maxDelta = 0.08;
    }

    final maxPrice = refClosePrice + maxDelta;
    // final minPrice = refClosePrice - maxDelta;
    final hZoomRatio = -size.height / (2 * maxDelta);

    // 绘制背景
    _drawFiveDayMinuteKlineBackground(canvas, refClosePrice, maxPrice);

    // 限制最大绘制数量
    final nTotalLine =
        state.fiveDayMinuteKlines.length > 1200 ? 1200 : state.fiveDayMinuteKlines.length;
    final w = size.width / 1200;

    // 准备绘制路径
    final pricePath = Path();
    final avgPricePath = Path();
    final pricePoints = <Offset>[];
    final avgPricePoints = <Offset>[];

    // 计算所有点
    for (var i = 0; i < nTotalLine; i++) {
      final kline = state.fiveDayMinuteKlines[i];
      final x = i * w;
      final y = (kline.price - maxPrice) * hZoomRatio;
      final yAvg = (kline.avgPrice - maxPrice) * hZoomRatio;

      if (i == 0) {
        pricePath.moveTo(x, y);
        avgPricePath.moveTo(x, yAvg);
      } else {
        pricePath.lineTo(x, y);
        avgPricePath.lineTo(x, yAvg);
      }

      pricePoints.add(Offset(x, y));
      avgPricePoints.add(Offset(x, yAvg));
    }

    // 绘制分时线
    canvas.drawPath(
      pricePath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // 绘制分时均线
    canvas.drawPath(
      avgPricePath,
      Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // 绘制渐变填充区域
    final fillPath =
        Path.from(pricePath)
          ..lineTo(nTotalLine * w, size.height)
          ..lineTo(0, size.height)
          ..close();

    final gradient = LinearGradient(
      colors: [Colors.red.withOpacity(0.24), Colors.red.withOpacity(0.02)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    canvas.drawPath(
      fillPath,
      Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _drawCrossLine(Canvas canvas, Size size) {
    final crossPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;

    // 获取当前K线数据
    final kline = state.klines[state.crossLineIndex];
    final x = state.crossLineIndex * state.klineWidth + state.klineInnerWidth / 2;

    // 水平线
    canvas.drawLine(
      Offset(0, (size.height) / 2),
      Offset(size.width, (size.height) / 2),
      crossPaint,
    );

    // 垂直线
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), crossPaint);

    // 显示价格信息
    _drawCrossLineInfo(canvas, size, kline, x);
  }

  void _drawCrossLineInfo(Canvas canvas, Size size, UiKline kline, double x) {
    final textStyle = TextStyle(color: Colors.white, fontSize: 12);

    final textPainter = TextPainter(
      text: TextSpan(
        text:
            'O:${kline.priceOpen.toStringAsFixed(2)} H:${kline.priceMax.toStringAsFixed(2)} '
            'L:${kline.priceMin.toStringAsFixed(2)} C:${kline.priceClose.toStringAsFixed(2)}',
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - 20));
  }
}

class KlineCtrl extends ConsumerWidget {
  const KlineCtrl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(klineProvider);

    return Row(
      children: [
        // K线类型切换
        _buildTypeButton(context, ref, '分时', KlineType.minute),
        _buildTypeButton(context, ref, '五日', KlineType.fiveDay),
        _buildTypeButton(context, ref, '日K', KlineType.day),
        _buildTypeButton(context, ref, '周K', KlineType.week),
        _buildTypeButton(context, ref, '月K', KlineType.month),

        const Spacer(),

        // 缩放控制
        IconButton(
          icon: const Icon(Icons.zoom_in, size: 20),
          onPressed: () => ref.read(klineProvider.notifier).zoomIn(),
        ),
        IconButton(
          icon: const Icon(Icons.zoom_out, size: 20),
          onPressed: () => ref.read(klineProvider.notifier).zoomOut(),
        ),

        // EMA控制
        _buildEmaButton(context, ref, 'MA5', 5),
        _buildEmaButton(context, ref, 'MA10', 10),
        _buildEmaButton(context, ref, 'MA20', 20),
      ],
    );
  }

  Widget _buildTypeButton(BuildContext context, WidgetRef ref, String text, KlineType type) {
    final currentType = ref.watch(klineProvider.select((state) => state.type));
    final isActive = currentType == type;

    return TextButton(
      style: TextButton.styleFrom(foregroundColor: isActive ? Colors.blue : Colors.white),
      onPressed: () => ref.read(klineProvider.notifier).setType(type),
      child: Text(text),
    );
  }

  Widget _buildEmaButton(BuildContext context, WidgetRef ref, String text, int period) {
    final hasEma = ref.watch(
      klineProvider.select((state) => state.emaCurves.any((ema) => ema.period == period)),
    );

    return TextButton(
      style: TextButton.styleFrom(foregroundColor: hasEma ? Colors.blue : Colors.white),
      onPressed: () {
        if (hasEma) {
          ref.read(klineProvider.notifier).removeEmaCurve(period);
        } else {
          ref.read(klineProvider.notifier).addEmaCurve(period, _getEmaColor(period));
        }
      },
      child: Text(text),
    );
  }

  Color _getEmaColor(int period) {
    return switch (period) {
      5 => Colors.green,
      10 => Colors.white,
      20 => const Color(0xFFEF486F),
      30 => const Color(0xFFFF9F1A),
      60 => const Color(0xFFC9F3F0),
      _ => Colors.purple,
    };
  }
}
