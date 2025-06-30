// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/ui/settings/task_download_curve_painter.dart
// Purpose:     task download curve custom painter
// Author:      songhuabiao
// Created:     2025-06-30 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:irich/service/task_scheduler.dart';

class TaskDownloadCurvePainter extends CustomPainter {
  final List<TaskRequestLog> logs;
  final Duration timeRange;
  final Color curveColor;
  final double curveWidth;

  // 添加内边距参数
  final EdgeInsets padding = EdgeInsets.all(10);

  TaskDownloadCurvePainter({
    required this.logs,
    this.timeRange = const Duration(minutes: 5),
    this.curveColor = Colors.blue,
    this.curveWidth = 2.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.isEmpty) return;

    // 1. 计算实际绘制区域
    final drawArea = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.horizontal,
      size.height - padding.vertical,
    );
    _drawBackground(canvas, size);
    // 3. 应用绘制区域约束
    canvas.save();
    canvas.clipRect(drawArea);

    // 1. 计算坐标范围
    final now = DateTime.now();
    final minTime = now.subtract(timeRange);
    final maxBytes = logs.map((log) => log.log.responseBytes).reduce(max).toDouble();

    Size actualSize = Size(drawArea.width, drawArea.height);
    canvas.translate(padding.left, padding.top);
    // 2. 绘制渐变背景
    _drawGradientBackground(canvas, actualSize);

    // 3. 绘制曲线和填充
    _drawCurveWithGradientFill(canvas, actualSize, minTime, now, maxBytes);
    canvas.restore();
  }

  void _drawGradientBackground(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.grey[50]!, Colors.grey[100]!],
      stops: [0.3, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.grey[100]!);
  }

  void _drawCurveWithGradientFill(
    Canvas canvas,
    Size size,
    DateTime minTime,
    DateTime maxTime,
    double maxBytes,
  ) {
    final points = _calculatePoints(size, minTime, maxTime, maxBytes);
    if (points.isEmpty) return;

    // 创建路径
    final path = Path()..moveTo(points.first.dx, points.first.dy);

    // 使用贝塞尔曲线平滑连接点
    for (int i = 1; i < points.length; i++) {
      final controlPoint1 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i - 1].dy);
      final controlPoint2 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i].dy);
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        points[i].dx,
        points[i].dy,
      );
    }

    // 创建填充路径（闭合到X轴）
    final fillPath =
        Path.from(path)
          ..lineTo(points.last.dx, size.height)
          ..lineTo(points.first.dx, size.height)
          ..close();

    // 绘制上下渐变填充
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [curveColor.withOpacity(0.4), curveColor.withOpacity(0.1), Colors.transparent],
      stops: [0.0, 0.5, 1.0],
    );
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = fillGradient.createShader(
          Rect.fromPoints(Offset(0, 0), Offset(size.width, size.height)),
        ),
    );

    // 绘制曲线
    canvas.drawPath(
      path,
      Paint()
        ..color = curveColor
        ..strokeWidth = curveWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // 可选：添加数据点标记
    _drawDataPoints(canvas, points);
  }

  List<Offset> _calculatePoints(Size size, DateTime minTime, DateTime maxTime, double maxBytes) {
    return logs.map((log) {
      final x = log.percent * size.width;
      final y = _convertBytesToY(log.log.responseBytes, maxBytes, size.height);
      return Offset(x, y);
    }).toList();
  }

  double _convertBytesToY(int bytes, double maxBytes, double height) {
    return height - (bytes / maxBytes) * height;
  }

  // 绘制数据点标记（可选）
  void _drawDataPoints(Canvas canvas, List<Offset> points) {
    final paint =
        Paint()
          ..color = curveColor
          ..strokeWidth = 3
          ..style = PaintingStyle.fill;

    // 只绘制部分关键点（避免拥挤）
    final step = (points.length / 5).ceil();
    for (int i = 0; i < points.length; i += step) {
      canvas.drawCircle(points[i], 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
