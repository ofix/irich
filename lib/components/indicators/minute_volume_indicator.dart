import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/store/components/state_kline.dart';
import 'package:irich/store/indicators/state_minute_volume_indicator.dart';
import 'package:irich/types/stock.dart';

class MinuteVolumeIndicator extends ConsumerWidget {
  final double height;

  const MinuteVolumeIndicator({super.key, this.height = 100});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(minuteVolumeProvider);
    final klineState = ref.watch(klineProvider);

    if (!state.visible || state.volumes.isEmpty) {
      return SizedBox(height: height);
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _MinuteVolumePainter(
          volumes: state.volumes,
          prices: state.prices,
          maxVolume: state.maxVolume,
          crossLineIndex: state.crossLineIndex,
          klineType: state.klineType,
          width: klineState.width,
        ),
      ),
    );
  }
}

class _MinuteVolumePainter extends CustomPainter {
  final List<double> volumes;
  final List<double> prices;
  final double maxVolume;
  final int crossLineIndex;
  final KlineType klineType;
  final double width;

  _MinuteVolumePainter({
    required this.volumes,
    required this.prices,
    required this.maxVolume,
    required this.crossLineIndex,
    required this.klineType,
    required this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (volumes.isEmpty) return;

    // 绘制成交量柱状图
    _drawVolumeBars(canvas, size);

    // 绘制边框和网格
    _drawGridAndBorder(canvas, size);

    // 绘制十字线
    if (crossLineIndex != -1) {
      _drawCrossLine(canvas, size);
    }
  }

  void _drawVolumeBars(Canvas canvas, Size size) {
    final innerWidth = width;
    final maxLines = klineType == KlineType.minute ? 240 : 1200;
    final barWidth = innerWidth / maxLines;
    final totalLines =
        klineType == KlineType.minute
            ? volumes.length.clamp(0, 240)
            : volumes.length.clamp(0, 1200);

    // final redPaint = Paint()..color = Colors.red;
    // final greenPaint = Paint()..color = Colors.green;
    // final grayPaint = Paint()..color = Colors.grey;

    for (int i = 1; i < totalLines; i++) {
      final x = i * barWidth;
      final y = size.height * (1 - volumes[i] / maxVolume);
      final h = size.height * volumes[i] / maxVolume;

      final paint = _getVolumePaint(i);
      canvas.drawLine(Offset(x, y), Offset(x, y + h), paint);
    }
  }

  Paint _getVolumePaint(int index) {
    if (index >= prices.length || index < 1) return Paint()..color = Colors.grey;

    if (prices[index] > prices[index - 1]) {
      return Paint()..color = Colors.red;
    } else if (prices[index] < prices[index - 1]) {
      return Paint()..color = Colors.green;
    } else {
      return Paint()..color = Colors.grey;
    }
  }

  void _drawGridAndBorder(Canvas canvas, Size size) {
    // 绘制边框
    final borderPaint =
        Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    canvas.drawRect(Rect.fromLTWH(0, 0, width, size.height), borderPaint);

    // 绘制水平网格线
    final hRow = size.height / 4;
    final dotPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    for (int i = 1; i <= 3; i++) {
      final y = i * hRow;
      canvas.drawLine(Offset(0, y), Offset(width, y), dotPaint);
    }

    // 绘制垂直网格线
    final nCols = klineType == KlineType.minute ? 8 : 20;
    final wCol = (width) / nCols;

    for (int i = 1; i < nCols; i++) {
      if (i % 4 == 0) continue;
      final x = i * wCol;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), dotPaint);
    }

    // 绘制粗垂直网格线
    final solidPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    for (int i = 4; i < nCols; i += 4) {
      final x = i * wCol;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), solidPaint);
    }

    // 绘制刻度标签
    final textStyle = TextStyle(color: Colors.grey, fontSize: 10);
    final rowVolume = maxVolume / 4;

    for (int i = 0; i <= 4; i++) {
      final label = _formatVolume(maxVolume - rowVolume * i);
      final y = i * hRow;

      // 左侧标签
      _drawText(canvas, label, Offset(-4, y), textStyle, TextAlign.right);

      // 右侧标签
      _drawText(canvas, label, Offset(width + 4, y), textStyle, TextAlign.left);
    }
  }

  void _drawCrossLine(Canvas canvas, Size size) {
    final innerWidth = width;
    final maxLines = klineType == KlineType.minute ? 240 : 1200;
    final barWidth = innerWidth / maxLines;

    final x = crossLineIndex * barWidth;

    final crossPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..strokeWidth = 0.5;

    // 垂直线
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), crossPaint);
  }

  void _drawText(Canvas canvas, String text, Offset position, TextStyle style, TextAlign align) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();

    textPainter.paint(canvas, position - Offset(0, textPainter.height / 2));
  }

  String _formatVolume(double volume) {
    if (volume >= 100000000) {
      return '${(volume / 100000000).toStringAsFixed(2)}亿';
    } else if (volume >= 10000) {
      return '${(volume / 10000).toStringAsFixed(2)}万';
    }
    return volume.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
