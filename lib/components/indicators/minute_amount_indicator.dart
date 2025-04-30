import 'package:flutter/material.dart';
import 'package:irich/types/stock.dart';

class MinuteAmountIndicator extends StatefulWidget {
  final double width;
  final double height;
  final List<MinuteKline> minuteKlines;
  final KlineType klineType;
  final int crossLineIndex;
  const MinuteAmountIndicator({
    super.key,
    required this.minuteKlines,
    required this.klineType,
    required this.crossLineIndex,
    this.width = 800,
    this.height = 100,
  });

  @override
  State<MinuteAmountIndicator> createState() => _MinuteAmountIndicatorState();
}

class _MinuteAmountIndicatorState extends State<MinuteAmountIndicator> {
  @override
  Widget build(BuildContext context) {
    if (widget.minuteKlines.isEmpty) {
      return SizedBox(height: widget.height);
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: _MinuteVolumePainter(
          klines: widget.minuteKlines,
          klineType: widget.klineType,
          crossLineIndex: widget.crossLineIndex,
        ),
      ),
    );
  }
}

class _MinuteVolumePainter extends CustomPainter {
  final List<MinuteKline> klines;
  final int crossLineIndex;
  final KlineType klineType;
  late final double maxAmount;

  _MinuteVolumePainter({
    required this.klines,
    required this.crossLineIndex,
    required this.klineType,
  }) {
    maxAmount = calcMaxAmount().toDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (klines.isEmpty) return;
    // 绘制成交量柱状图
    _drawVolumeBars(canvas, size);
    // 绘制边框和网格
    _drawGridAndBorder(canvas, size);
    // 绘制十字线
    if (crossLineIndex != -1) {
      _drawCrossLine(canvas, size);
    }
  }

  double calcMaxAmount() {
    if (klines.isEmpty) return 0;
    return klines.map((k) => k.amount).reduce((a, b) => a > b ? a : b);
  }

  void _drawVolumeBars(Canvas canvas, Size size) {
    final maxKlines = klineType == KlineType.minute ? 240 : 1200;
    final barWidth = size.width / maxKlines;
    final totalLines =
        klineType == KlineType.minute ? klines.length.clamp(0, 240) : klines.length.clamp(0, 1200);

    for (int i = 1; i < totalLines; i++) {
      final x = i * barWidth;
      final y = size.height * (1 - klines[i].volume / BigInt.from(maxAmount));
      final h = size.height * klines[i].volume.toDouble() / maxAmount;

      final paint = _getVolumePaint(i);
      canvas.drawLine(Offset(x, y), Offset(x, y + h), paint);
    }
  }

  Paint _getVolumePaint(int index) {
    if (index >= klines.length || index < 1) return Paint()..color = Colors.grey;
    if (klines[index].price > klines[index - 1].price) {
      return Paint()..color = Colors.red;
    } else if (klines[index].price < klines[index - 1].price) {
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

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    // 绘制水平网格线
    final hRow = size.height / 4;
    final dotPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    for (int i = 1; i <= 3; i++) {
      final y = i * hRow;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), dotPaint);
    }

    // 绘制垂直网格线
    final nCols = klineType == KlineType.minute ? 8 : 20;
    final wCol = (size.width) / nCols;

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
    final rowVolume = maxAmount / 4;

    for (int i = 0; i <= 4; i++) {
      final label = _formatVolume(maxAmount - rowVolume * i);
      final y = i * hRow;
      // 左侧标签
      _drawLabel(canvas, label, Offset(-4, y), textStyle, TextAlign.right);
      // 右侧标签
      _drawLabel(canvas, label, Offset(size.width + 4, y), textStyle, TextAlign.left);
    }
  }

  void _drawCrossLine(Canvas canvas, Size size) {
    final maxLines = klineType == KlineType.minute ? 240 : 1200;
    final barWidth = size.width / maxLines;

    final x = crossLineIndex * barWidth;

    final crossPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..strokeWidth = 0.5;

    // 垂直线
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), crossPaint);
  }

  // 绘制右侧标签
  void _drawLabel(Canvas canvas, String text, Offset position, TextStyle style, TextAlign align) {
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
