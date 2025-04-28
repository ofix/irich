import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/store/components/state_kline.dart';
import 'package:irich/store/indicators/state_volume_indicator.dart';
import 'package:irich/types/stock.dart';

class VolumeIndicator extends ConsumerWidget {
  final double height;

  const VolumeIndicator({super.key, this.height = 100});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(volumeIndicatorProvider);
    final klineState = ref.watch(klineProvider);

    if (!state.visible || state.volumes.isEmpty) {
      return SizedBox(height: height);
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _VolumeIndicatorPainter(
          volumes: state.volumes,
          maxVolume: state.maxVolume,
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

class _VolumeIndicatorPainter extends CustomPainter {
  final List<double> volumes;
  final double maxVolume;
  final int crossLineIndex;
  final double klineWidth;
  final double klineInnerWidth;
  final List<bool> isUpList;

  _VolumeIndicatorPainter({
    required this.volumes,
    required this.maxVolume,
    required this.crossLineIndex,
    required this.klineWidth,
    required this.klineInnerWidth,
    required this.isUpList,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (volumes.isEmpty) return;

    // 绘制标题栏
    _drawTitleBar(canvas, size);

    // 绘制成交量柱状图
    _drawVolumeBars(canvas, size);

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
        text: '昨: ${_formatVolume(volumes.isNotEmpty ? volumes[0] : 0)}',
        style: textStyle.copyWith(color: Colors.grey),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    yesterdayText.paint(canvas, Offset(textPainter.width + 12, 4));

    // 绘制今日成交额
    final todayText = TextPainter(
      text: TextSpan(
        text: '今: ${_formatVolume(volumes.isNotEmpty ? volumes.last : 0)}',
        style: textStyle.copyWith(color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    todayText.paint(canvas, Offset(textPainter.width + yesterdayText.width + 24, 4));
  }

  void _drawVolumeBars(Canvas canvas, Size size) {
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

    for (int i = 0; i < volumes.length; i++) {
      final x = i * klineWidth;
      final barWidth = klineInnerWidth;
      final barHeight = (volumes[i] / maxVolume) * bodyHeight;
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

  String _formatVolume(double volume) {
    if (volume >= 100000000) {
      return '${(volume / 100000000).toStringAsFixed(2)}亿';
    } else if (volume >= 10000) {
      return '${(volume / 10000).toStringAsFixed(2)}万';
    }
    return volume.toStringAsFixed(2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
