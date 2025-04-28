import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/store/indicators/state_amount_indicator.dart';
import 'package:irich/store/components/state_kline.dart';
import 'package:irich/types/stock.dart';

class AmountIndicator extends ConsumerWidget {
  final double height;

  const AmountIndicator({super.key, this.height = 100});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(amountIndicatorProvider);
    final klineState = ref.watch(klineProvider);

    if (!state.visible || state.amounts.isEmpty) {
      return SizedBox(height: height);
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _AmountIndicatorPainter(
          amounts: state.amounts,
          maxAmount: state.maxAmount,
          crossLineIndex: state.crossLineIndex,
          klineWidth: klineState.klineWidth,
          klineInnerWidth: klineState.klineInnerWidth,
          isUpList: _getIsUpList(klineState.klines),
        ),
      ),
    );
  }

  List<bool> _getIsUpList(List<UiKline> klines) {
    return klines.map((k) => k.priceClose >= k.priceOpen).toList();
  }
}

class _AmountIndicatorPainter extends CustomPainter {
  final List<double> amounts;
  final double maxAmount;
  final int crossLineIndex;
  final double klineWidth;
  final double klineInnerWidth;
  final List<bool> isUpList;

  _AmountIndicatorPainter({
    required this.amounts,
    required this.maxAmount,
    required this.crossLineIndex,
    required this.klineWidth,
    required this.klineInnerWidth,
    required this.isUpList,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amounts.isEmpty) return;

    // 绘制标题栏
    _drawTitleBar(canvas, size);

    // 绘制成交额柱状图
    _drawAmountBars(canvas, size);

    // 绘制十字线
    if (crossLineIndex != -1) {
      _drawCrossLine(canvas, size);
    }
  }

  void _drawTitleBar(Canvas canvas, Size size) {
    const titleHeight = 20.0;
    final textStyle = TextStyle(color: Colors.white, fontSize: 12);

    // 绘制标题背景
    final bgPaint =
        Paint()
          ..color = const Color(0xFF252525)
          ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, titleHeight), bgPaint);

    // 绘制标题文本
    final textPainter = TextPainter(
      text: TextSpan(text: '成交额', style: textStyle.copyWith(color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(4, 4));

    // 绘制昨日成交额
    final yesterdayText = TextPainter(
      text: TextSpan(
        text: '昨: ${_formatAmount(amounts.isNotEmpty ? amounts[0] : 0)}',
        style: textStyle.copyWith(color: Colors.grey),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    yesterdayText.paint(canvas, Offset(textPainter.width + 12, 4));

    // 绘制今日成交额
    final todayText = TextPainter(
      text: TextSpan(
        text: '今: ${_formatAmount(amounts.isNotEmpty ? amounts.last : 0)}',
        style: textStyle.copyWith(color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    todayText.paint(canvas, Offset(textPainter.width + yesterdayText.width + 24, 4));
  }

  void _drawAmountBars(Canvas canvas, Size size) {
    const titleHeight = 20.0;
    final bodyHeight = size.height - titleHeight;

    final redPaint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

    final greenPaint =
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.fill;

    for (int i = 0; i < amounts.length; i++) {
      final x = i * klineWidth;
      final barWidth = klineInnerWidth;
      final barHeight = (amounts[i] / maxAmount) * bodyHeight;
      final y = titleHeight + bodyHeight - barHeight;

      // 根据涨跌决定颜色
      final paint = isUpList[i] ? redPaint : greenPaint;

      canvas.drawRect(Rect.fromLTWH(x, y, barWidth, barHeight), paint);
    }
  }

  void _drawCrossLine(Canvas canvas, Size size) {
    const titleHeight = 20.0;
    final crossPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;

    final x = crossLineIndex * klineWidth + klineInnerWidth / 2;

    // 垂直线
    canvas.drawLine(Offset(x, titleHeight), Offset(x, size.height), crossPaint);
  }

  String _formatAmount(double amount) {
    if (amount >= 100000000) {
      return '${(amount / 100000000).toStringAsFixed(2)}亿';
    } else if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(2)}万';
    }
    return amount.toStringAsFixed(2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
