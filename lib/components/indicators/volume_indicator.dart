// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/indicators/volume_indicator.dart
// Purpose:     volume indicator
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_chart_common.dart';
import 'package:irich/global/stock.dart';

class VolumeIndicator extends StatefulWidget {
  final KlineState klineState;

  const VolumeIndicator({super.key, required this.klineState});

  @override
  State<VolumeIndicator> createState() => _VolumeIndicatorState();
}

class _VolumeIndicatorState extends State<VolumeIndicator> {
  @override
  Widget build(BuildContext context) {
    KlineState state = widget.klineState;
    if (state.klines.isEmpty) {
      return SizedBox(width: state.klineChartWidth, height: state.indicatorChartHeight);
    }

    return SizedBox(
      width: state.klineChartWidth + state.klineChartLeftMargin + state.klineChartRightMargin,
      height: state.indicatorChartHeight,
      child: CustomPaint(
        painter: _VolumeIndicatorPainter(
          klines: state.klines,
          klineRng: state.klineRng!,
          crossLineIndex: state.crossLineIndex,
          klineStep: state.klineStep,
          klineWidth: state.klineWidth,
          isUpList: _getIsUpList(state.klines),
          klineChartWidth: state.klineChartWidth,
          klineChartLeftMargin: state.klineChartLeftMargin,
          klineChartRightMargin: state.klineChartRightMargin,
        ),
      ),
    );
  }

  List<bool> _getIsUpList(List<UiKline> klines) {
    return klines.map((k) => k.priceClose >= k.priceOpen).toList();
  }
}

class _VolumeIndicatorPainter extends CustomPainter {
  final List<UiKline> klines; // 绘制K线
  final UiKlineRange klineRng; // 可视K线范围
  final int crossLineIndex; // 当前光标所在K线位置
  final double klineStep; // K线宽度
  final double klineWidth; // K线内部宽度
  final List<bool> isUpList; // 红绿盘列表
  final double klineChartWidth; // K线图宽度
  final double klineChartLeftMargin; // K线图左边距
  final double klineChartRightMargin; // K线图右边距
  final double titleHeight = 20;

  _VolumeIndicatorPainter({
    required this.klines,
    required this.klineRng,
    required this.crossLineIndex,
    required this.klineStep,
    required this.klineWidth,
    required this.isUpList,
    required this.klineChartWidth,
    required this.klineChartLeftMargin,
    required this.klineChartRightMargin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (klines.isEmpty) return;
    // 绘制标题栏
    drawTitleBar(canvas, size);
    // 绘制成交量柱状图
    drawVolumeBars(canvas, size.height);
    // 绘制十字线
    if (crossLineIndex != -1) {
      drawCrossLine(canvas, size.height);
    }
  }

  void drawTitleBar(Canvas canvas, Size size) {
    final textStyle = TextStyle(color: Colors.white, fontSize: 12);

    // 绘制标题背景
    final bgPaint =
        Paint()
          ..color = const Color(0xFF252525)
          ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, titleHeight), bgPaint);

    // 绘制标题文本
    final textPainter = TextPainter(
      text: TextSpan(text: '成交量', style: textStyle.copyWith(color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(4, 4));

    // 绘制昨日成交量
    String yesterdayVolume = "--";
    if (klines.isNotEmpty) {
      yesterdayVolume = _formatVolume(klines.first.volume.toDouble());
    }
    final yesterdayText = TextPainter(
      text: TextSpan(text: '昨: $yesterdayVolume', style: textStyle.copyWith(color: Colors.grey)),
      textDirection: TextDirection.ltr,
    )..layout();
    yesterdayText.paint(canvas, Offset(textPainter.width + 12, 4));

    // 绘制今日成交量
    String todayVolume = "--";
    if (klines.isNotEmpty) {
      todayVolume = _formatVolume(klines.last.volume.toDouble());
    }
    final todayText = TextPainter(
      text: TextSpan(text: '今: $todayVolume}', style: textStyle.copyWith(color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    todayText.paint(canvas, Offset(textPainter.width + yesterdayText.width + 24, 4));
  }

  void drawVolumeBars(Canvas canvas, double height) {
    final bodyHeight = height - titleHeight;

    final redPaint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

    final greenPaint =
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.fill;

    BigInt maxVolume = _calcMaxVolume();

    canvas.save();
    canvas.translate(klineChartLeftMargin, 0);
    int nKline = 0;
    for (int i = klineRng.begin; i < klineRng.end; i++) {
      final x = nKline * klineStep;
      final barWidth = klineWidth;
      final barHeight = (klines[i].volume / maxVolume) * bodyHeight;
      final y = titleHeight + bodyHeight - barHeight;

      // 根据涨跌决定颜色
      final paint = isUpList[nKline] ? redPaint : greenPaint;

      canvas.drawRect(Rect.fromLTWH(x, y, barWidth, barHeight), paint);
      nKline++;
    }
    canvas.restore();
  }

  void drawCrossLine(Canvas canvas, double height) {
    canvas.save();
    canvas.translate(klineChartLeftMargin, 0);
    drawVerticalLine(
      canvas: canvas,
      x: crossLineIndex * klineStep + klineWidth / 2,
      yTop: titleHeight,
      yBottom: height,
    );
    canvas.restore();
  }

  String _formatVolume(double volume) {
    if (volume >= 100000000) {
      return '${(volume / 100000000).toStringAsFixed(2)}亿';
    } else if (volume >= 10000) {
      return '${(volume / 10000).toStringAsFixed(2)}万';
    }
    return volume.toStringAsFixed(2);
  }

  BigInt _calcMaxVolume() {
    if (klines.isEmpty) return BigInt.from(0);
    BigInt maxVolume = BigInt.from(0);
    for (int i = klineRng.begin; i < klineRng.end; i++) {
      if (klines[i].volume > maxVolume) {
        maxVolume = klines[i].volume;
      }
    }
    return maxVolume;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
