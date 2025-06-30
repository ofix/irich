// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/ui/settings/task_download_curve.dart
// Purpose:     task download curve custom painter
// Author:      songhuabiao
// Created:     2025-06-30 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:irich/pages/settings/task_download_curve_painter.dart';
import 'package:irich/service/task_scheduler.dart';

class TaskDownloadCurve extends StatefulWidget {
  final List<TaskRequestLog> logs;
  const TaskDownloadCurve({super.key, required this.logs});
  @override
  State<TaskDownloadCurve> createState() => _TaskDownloadCurveState();
}

class _TaskDownloadCurveState extends State<TaskDownloadCurve> {
  Offset? _hoverPosition; // 光标位置
  TaskRequestLog? _hoveredLog; // 对应数据点

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 10), // 左、上、右、下边距
            child:
            // 绘制区域（包裹MouseRegion）
            MouseRegion(
              onHover: (event) => _handleHover(event, context.size),
              onExit: (_) => setState(() => _hoverPosition = null),
              child: SizedBox.expand(
                child: CustomPaint(
                  painter: TaskDownloadCurvePainter(
                    logs: widget.logs,
                    curveColor: const Color.fromARGB(255, 4, 196, 97),
                  ),
                ),
              ),
            ),
          ),

          // 浮动信息面板
          if (_hoverPosition != null && _hoveredLog != null)
            Positioned(
              left: _hoverPosition!.dx + 20, // 偏移避免遮挡
              top: _hoverPosition!.dy - 40,
              child: _buildTooltip(_hoveredLog!),
            ),
        ],
      ),
    );
  }

  void _handleHover(PointerHoverEvent event, Size? canvasSize) {
    if (canvasSize == null) return;

    setState(() {
      _hoverPosition = event.localPosition;
      _hoveredLog = _findNearestLog(event.localPosition, canvasSize);
    });
  }

  TaskRequestLog? _findNearestLog(Offset position, Size canvasSize) {
    if (widget.logs.isEmpty) return null;

    // 1. 计算当前光标位置对应的百分比 (0.0 ~ 1.0)
    final double targetPercent = position.dx.clamp(0.0, canvasSize.width) / canvasSize.width;

    // 2. 二分查找最近percent的日志
    return _binarySearchByPercent(widget.logs, targetPercent);
  }

  TaskRequestLog? _binarySearchByPercent(List<TaskRequestLog> logs, double targetPercent) {
    // 边界检查
    if (logs.isEmpty) return null;
    if (targetPercent <= logs.first.percent) return logs.first;
    if (targetPercent >= logs.last.percent) return logs.last;

    // 二分查找核心逻辑
    int low = 0;
    int high = logs.length - 1;
    TaskRequestLog? nearestLog;
    double minDiff = double.infinity;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final currentLog = logs[mid];
      final currentPercent = currentLog.percent;
      final diff = (currentPercent - targetPercent).abs();

      // 更新最近记录
      if (diff < minDiff) {
        minDiff = diff;
        nearestLog = currentLog;
      }

      if (currentPercent < targetPercent) {
        low = mid + 1;
      } else if (currentPercent > targetPercent) {
        high = mid - 1;
      } else {
        return currentLog; // 精确匹配
      }
    }

    // 检查相邻点（确保全局最近）
    final candidates =
        [
          if (nearestLog != null && nearestLog != logs.first) logs[logs.indexOf(nearestLog!) - 1],
          nearestLog,
          if (nearestLog != null && nearestLog != logs.last) logs[logs.indexOf(nearestLog!) + 1],
        ].whereType<TaskRequestLog>().toList();

    return candidates.isEmpty
        ? null
        : candidates.reduce(
          (a, b) => (a.percent - targetPercent).abs() < (b.percent - targetPercent).abs() ? a : b,
        );
  }

  Widget _buildTooltip(TaskRequestLog requstLog) {
    final log = requstLog.log;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '时间: ${DateFormat('HH:mm:ss.SSS').format(log.requestTime)}',
              style: TextStyle(color: Colors.white),
            ),
            Text(
              '速度: ${_formatSpeed(log.responseBytes, log.duration)}/s',
              style: TextStyle(color: Colors.blue[200]),
            ),
            Text('总量: ${_formatBytes(log.responseBytes)}', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  String _formatSpeed(int bytes, int seconds) {
    if (bytes <= 0 || seconds == 0) {
      return "0 B/s";
    }

    // 1. 计算速度（字节/秒）
    final double speed = bytes / seconds;

    // 2. 格式化单位
    const units = ["B/s", "KB/s", "MB/s", "GB/s"];
    int unitIndex = 0;
    double formattedSpeed = speed;

    while (formattedSpeed >= 1024 && unitIndex < units.length - 1) {
      formattedSpeed /= 1024;
      unitIndex++;
    }

    // 3. 根据数值大小动态调整小数位数
    String speedStr;
    if (formattedSpeed >= 100) {
      speedStr = formattedSpeed.toStringAsFixed(0);
    } else if (formattedSpeed >= 10) {
      speedStr = formattedSpeed.toStringAsFixed(1);
    } else {
      speedStr = formattedSpeed.toStringAsFixed(2);
    }

    // 4. 移除无意义的小数部分（如 "5.00" → "5"）
    if (speedStr.endsWith('.00')) {
      speedStr = speedStr.substring(0, speedStr.length - 3);
    } else if (speedStr.endsWith('0')) {
      speedStr = speedStr.substring(0, speedStr.length - 1);
    }

    return '$speedStr ${units[unitIndex]}';
  }

  // 字节格式化函数
  String _formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
