import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/store/components/state_kline.dart';
import 'package:irich/store/indicators/state_turnoverrate_indicator.dart';

class TurnoverRateIndicator extends ConsumerWidget {
  final double height;

  const TurnoverRateIndicator({super.key, this.height = 100});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(turnoverRateProvider);
    final klineState = ref.watch(klineProvider);

    if (!state.visible || state.turnoverRates.isEmpty) {
      return SizedBox(height: height);
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _TurnoverRatePainter(
          turnoverRates: state.turnoverRates,
          maxTurnoverRate: state.maxTurnoverRate,
          crossLineIndex: state.crossLineIndex,
          klineWidth: klineState.klineWidth,
          klineInnerWidth: klineState.klineInnerWidth,
          isUpList: state.isUpList,
        ),
      ),
    );
  }
}

class _TurnoverRatePainter extends CustomPainter {
  final List<double> turnoverRates;
  final double maxTurnoverRate;
  final int crossLineIndex;
  final double klineWidth;
  final double klineInnerWidth;
  final List<bool> isUpList;

  _TurnoverRatePainter({
    required this.turnoverRates,
    required this.maxTurnoverRate,
    required this.crossLineIndex,
    required this.klineWidth,
    required this.klineInnerWidth,
    required this.isUpList,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (turnoverRates.isEmpty) return;

    // 绘制标题栏
    _drawTitleBar(canvas, size);

    // 绘制换手率柱状图
    _drawTurnoverRateBars(canvas, size);

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
      text: TextSpan(text: '换手率', style: textStyle.copyWith(color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(4, 4));

    // 绘制昨日换手率
    final yesterdayText = TextPainter(
      text: TextSpan(
        text: '昨: ${_formatRate(turnoverRates.isNotEmpty ? turnoverRates[0] : 0)}',
        style: textStyle.copyWith(color: Colors.grey),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    yesterdayText.paint(canvas, Offset(textPainter.width + 12, 4));

    // 绘制今日换手率
    final todayText = TextPainter(
      text: TextSpan(
        text: '今: ${_formatRate(turnoverRates.isNotEmpty ? turnoverRates.last : 0)}',
        style: textStyle.copyWith(color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    todayText.paint(canvas, Offset(textPainter.width + yesterdayText.width + 24, 4));
  }

  void _drawTurnoverRateBars(Canvas canvas, Size size) {
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

    for (int i = 0; i < turnoverRates.length; i++) {
      final x = i * klineWidth;
      final barWidth = klineInnerWidth;
      final barHeight = (turnoverRates[i] / maxTurnoverRate) * bodyHeight;
      final y = titleHeight + bodyHeight - barHeight;

      // 确保最小高度
      double effectiveHeight = barHeight < 2 ? 2 : barHeight;

      // 根据涨跌决定颜色
      final paint = isUpList[i] ? redPaint : greenPaint;

      canvas.drawRect(Rect.fromLTWH(x, y, barWidth, effectiveHeight), paint);
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

  String _formatRate(double rate) {
    return '${rate.toStringAsFixed(2)}%';
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
