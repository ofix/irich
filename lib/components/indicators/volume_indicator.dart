// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/indicators/volume_indicator.dart
// Purpose:     volume indicator
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/theme/stock_colors.dart';

class VolumeIndicator extends StatefulWidget {
  final KlineCtrlState klineCtrlState;
  final StockColors stockColors;

  const VolumeIndicator({super.key, required this.klineCtrlState, required this.stockColors});

  @override
  State<VolumeIndicator> createState() => _VolumeIndicatorState();
}

class _VolumeIndicatorState extends State<VolumeIndicator> {
  @override
  Widget build(BuildContext context) {
    KlineCtrlState state = widget.klineCtrlState;
    if (state.klines.isEmpty) {
      return SizedBox(width: state.klineChartWidth, height: state.indicatorChartHeight);
    }

    return SizedBox(
      width: state.klineCtrlWidth,
      height: state.indicatorChartHeight,
      child: CustomPaint(
        painter: _VolumeIndicatorPainter(
          klines: state.klines,
          klineRng: state.klineRng!,
          crossLineFollowKlineIndex: state.crossLineFollowKlineIndex,
          klineStep: state.klineStep,
          klineWidth: state.klineWidth,
          isUpList: _getIsUpList(state.klines),
          klineChartWidth: state.klineChartWidth,
          klineChartLeftMargin: state.klineChartLeftMargin,
          klineChartRightMargin: state.klineChartRightMargin,
          indicatorChartTitleBarHeight: state.indicatorChartTitleBarHeight,
          stockColors: widget.stockColors,
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
  final int crossLineFollowKlineIndex; // 当前光标所在K线位置
  final double klineStep; // K线宽度
  final double klineWidth; // K线内部宽度
  final List<bool> isUpList; // 红绿盘列表
  final double klineChartWidth; // K线图宽度
  final double klineChartLeftMargin; // K线图左边距
  final double klineChartRightMargin; // K线图右边距
  final double indicatorChartTitleBarHeight; // 标题栏高度
  final StockColors stockColors;
  late final double maxVolume;

  _VolumeIndicatorPainter({
    required this.klines,
    required this.klineRng,
    required this.crossLineFollowKlineIndex,
    required this.klineStep,
    required this.klineWidth,
    required this.isUpList,
    required this.klineChartWidth,
    required this.klineChartLeftMargin,
    required this.klineChartRightMargin,
    required this.indicatorChartTitleBarHeight,
    required this.stockColors,
  }) {
    maxVolume = _calcMaxVolume().toDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (klines.isEmpty) return;
    // 绘制标题栏
    drawTitleBar(canvas, size);
    // 绘制成交量柱状图
    drawVolumeBars(canvas, size.height);
    // 绘制左边成交量指示面板
    canvas.save();
    canvas.translate(-2, 0);
    drawKlinePane(
      type: KlinePaneType.volume,
      canvas: canvas,
      width: klineChartLeftMargin,
      height: size.height,
      reference: 0,
      min: 0,
      max: maxVolume,
      nRows: 4,
      textAlign: TextAlign.right,
      fontSize: 11,
      offsetY: indicatorChartTitleBarHeight,
    );
    canvas.restore();

    // 绘制右边成交量指示面板
    canvas.save();
    canvas.translate(klineChartLeftMargin + klineChartWidth + 2, 0);
    drawKlinePane(
      type: KlinePaneType.volume,
      canvas: canvas,
      width: klineChartLeftMargin,
      height: size.height,
      reference: 0,
      min: 0,
      max: maxVolume,
      nRows: 4,
      textAlign: TextAlign.left,
      fontSize: 11,
      offsetY: indicatorChartTitleBarHeight,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! _VolumeIndicatorPainter) return true;
    final old = oldDelegate;

    // 比较基础类型和引用
    if (old.klineStep != klineStep ||
        old.klineWidth != klineWidth ||
        old.klineChartWidth != klineChartWidth ||
        old.klineRng != klineRng ||
        old.stockColors != stockColors ||
        old.klineChartLeftMargin != klineChartLeftMargin ||
        old.klineChartRightMargin != klineChartRightMargin) {
      return true;
    }

    // 深度比较列表内容（假设列表顺序和长度决定是否更新）
    if (old.klines.length != klines.length) {
      return true;
    }

    return false;
  }

  void drawTitleBar(Canvas canvas, Size size) {
    // 昨日成交量
    String yesterdayVolume = "--";
    if (klines.isNotEmpty) {
      yesterdayVolume = formatVolume(klines.first.volume.toDouble());
    }
    // 今日成交量
    String todayVolume = "--";
    if (klines.isNotEmpty) {
      todayVolume = formatVolume(klines.last.volume.toDouble());
    }

    List<ColorText> words = [
      ColorText('成交量', Colors.grey),
      ColorText('昨: $yesterdayVolume', const Color.fromARGB(255, 191, 28, 28)),
      ColorText('今: $todayVolume', const Color.fromARGB(255, 49, 96, 224)),
    ];

    drawIndicatorTitleBar(
      canvas: canvas,
      words: words,
      width: size.width,
      offset: Offset(4, 0),
      height: indicatorChartTitleBarHeight,
    );
  }

  void drawVolumeBars(Canvas canvas, double height) {
    final bodyHeight = height - indicatorChartTitleBarHeight;

    final redPaint =
        Paint()
          ..color = stockColors.klineUp
          ..style = PaintingStyle.fill;

    final greenPaint =
        Paint()
          ..color = stockColors.klineDown
          ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(klineChartLeftMargin, 0);
    int nKline = 0;
    for (int i = klineRng.begin; i < klineRng.end; i++) {
      final x = nKline * klineStep;
      final barWidth = klineWidth;
      final barHeight = (klines[i].volume.toDouble() / maxVolume) * bodyHeight;
      final y = indicatorChartTitleBarHeight + bodyHeight - barHeight;

      // 根据涨跌决定颜色
      final paint = isUpList[nKline] ? redPaint : greenPaint;

      canvas.drawRect(Rect.fromLTWH(x, y, barWidth, barHeight), paint);
      nKline++;
    }
    canvas.restore();
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
}
