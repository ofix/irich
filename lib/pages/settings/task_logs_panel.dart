// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/ui/settings/task_logs_panel.dart
// Purpose:     select task logs panel
// Author:      songhuabiao
// Created:     2025-05-22 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:irich/components/svg_image.dart';
import 'package:irich/pages/settings/task_download_curve.dart';
import 'package:irich/service/request_log.dart';
import 'package:irich/service/task_scheduler.dart';
import 'package:irich/store/provider_task.dart';

class TaskLogsPanel extends ConsumerWidget {
  const TaskLogsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskProvider);
    final selectedLogs = taskState.selectedTaskLogs;

    if (taskState.selectedTask == null) {
      return const Center(child: Text('请选择任务'));
    }

    return Column(
      children: [
        TaskDownloadCurve(logs: taskState.selectedTaskLogs),
        // 日志列表
        Expanded(
          child: ListView.builder(
            itemCount: selectedLogs.length,
            itemBuilder: (context, index) {
              return RequestLogItem(
                requestLog: selectedLogs[index],
                index: index + 1,
                isLast: index == selectedLogs.length - 1,
              );
            },
          ),
        ),
      ],
    );
  }
}

class RequestLogItem extends StatelessWidget {
  final TaskRequestLog requestLog;
  final bool isLast;
  final int index;

  const RequestLogItem({
    super.key,
    required this.requestLog,
    required this.index,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getBackgroundColor(requestLog.log),
            borderRadius: BorderRadius.circular(0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 水平分布
            crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中
            children: [
              SizedBox(
                width: 40,
                child: Padding(padding: const EdgeInsets.only(right: 8), child: _buildIndex(index)),
              ),
              // 请求供应商品牌LOGO
              SizedBox(
                width: 64,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildRequestProvider(requestLog.log),
                ),
              ),
              // 请求API类型名称
              SizedBox(
                width: 80,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildProviderName(requestLog.log, context),
                ),
              ),
              SizedBox(
                width: 50,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildResponseStatusCode(requestLog.log, context),
                ),
              ),
              // 请求URL
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildRequestUrl(requestLog.log),
                ),
              ),
              // 请求时间
              SizedBox(
                width: 140,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildRequestTime(requestLog.log),
                ),
              ),
              // 响应数据大小
              SizedBox(
                width: 120,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildResponseBytes(requestLog.log),
                ),
              ),
              // 请求耗时
              SizedBox(
                width: 90,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildRequestDuration(requestLog.log),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getBackgroundColor(RequestLog log) {
    if (log.statusCode == null || log.statusCode! >= 400) {
      return Colors.red.withOpacity(0.05);
    }
    return Colors.white.withOpacity(0.8); // 浅蓝色背景
  }

  // 序号
  Widget _buildIndex(int index) {
    return Text(
      index.toString(),
      textAlign: TextAlign.right,
      style: TextStyle(fontSize: 12, color: const Color.fromARGB(255, 50, 50, 50)),
    );
  }

  // 供应商图标
  Widget _buildRequestProvider(RequestLog log) {
    return SizedBox(
      width: 24,
      height: 24,
      child: SvgImage(assetPath: 'images/${log.providerId.name}.svg', width: 24, height: 24),
    );
  }

  // 供应商名称
  Widget _buildProviderName(RequestLog log, BuildContext context) {
    return Text.rich(
      TextSpan(
        text: log.apiType.name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: Color.fromARGB(255, 0, 0, 0),
        ),
      ),
    );
  }

  // 响应状态码
  Widget _buildResponseStatusCode(RequestLog log, BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '${log.statusCode ?? 'N/A'}',
        style: TextStyle(color: _getStatusCodeColor(log), fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusCodeColor(RequestLog log) {
    if (log.statusCode == null) return Colors.grey;
    if (log.statusCode! >= 200 && log.statusCode! < 300) return Colors.green;
    if (log.statusCode! >= 400 && log.statusCode! < 500) return Colors.orange;
    return Colors.red;
  }

  // 请求耗时
  Widget _buildRequestDuration(RequestLog log) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getDurationColor(log).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _getDurationColor(log).withOpacity(0.3)),
      ),
      child: Text(
        '${log.duration} ms',
        textAlign: TextAlign.center, // 添加这一行
        style: TextStyle(color: _getDurationColor(log), fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getDurationColor(RequestLog log) {
    if (log.duration < 500) return Colors.green;
    if (log.duration < 2000) return const Color.fromARGB(255, 192, 115, 1);
    return Colors.red;
  }

  // 请求URL
  Widget _buildRequestUrl(RequestLog log) {
    return Text(
      log.url,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        color: Color.fromARGB(255, 40, 121, 241),
      ),
    );
  }

  // 请求时间
  Widget _buildRequestTime(RequestLog log) {
    return Text(
      DateFormat('HH:mm:ss.SSS').format(log.requestTime),
      style: TextStyle(fontSize: 12, color: const Color.fromARGB(255, 52, 50, 50)),
    );
  }

  // 响应数据大小
  Widget _buildResponseBytes(RequestLog log) {
    return Text(
      _formatBytes(log.responseBytes), // 使用格式化函数
      style: TextStyle(fontSize: 12, color: const Color.fromARGB(255, 50, 50, 50)),
    );
  }

  // 字节格式化函数
  String _formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}
