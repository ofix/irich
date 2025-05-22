// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/ui/settings/task_logs_panel.dart
// Purpose:     select task logs panel
// Author:      songhuabiao
// Created:     2025-05-22 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:irich/components/svg_image.dart';
import 'package:irich/service/request_log.dart';
import 'package:irich/store/state_tasks.dart';

class TaskLogsPanel extends ConsumerWidget {
  const TaskLogsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTask = ref.watch(selectedTaskProvider);
    final selectedLogs = ref.watch(selectedTaskLogsProvider);
    final stats = ref.watch(taskStatsProvider);

    if (selectedTask == null) {
      return const Center(child: Text('请选择任务'));
    }

    return Column(
      children: [
        // 标题和统计信息栏
        _buildLogListHeader(context, ref, stats),

        // 日志列表
        Expanded(
          child: ListView.builder(
            itemCount: selectedLogs.length,
            itemBuilder: (context, index) {
              return RequestLogItem(
                log: selectedLogs[index],
                isLast: index == selectedLogs.length - 1,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogListHeader(BuildContext context, WidgetRef ref, Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Color.fromARGB(255, 200, 200, 200), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('请求日志 (${stats['total']}条)', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              _buildStatsChip('成功: ${stats['success']}', Colors.green),
              const SizedBox(width: 8),
              _buildStatsChip('失败: ${stats['failed']}', Colors.red),
              const SizedBox(width: 8),
              _buildStatsChip('平均耗时: ${stats['avgDuration'].toStringAsFixed(0)}ms', Colors.blue),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatsChip(String text, Color color) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class RequestLogItem extends StatelessWidget {
  final RequestLog log;
  final bool isLast;

  const RequestLogItem({super.key, required this.log, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getBackgroundColor(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildStatusInfo(context),
              const SizedBox(height: 8),
              _buildTimingInfo(context),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 24, endIndent: 24),
      ],
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    if (log.statusCode == null || log.statusCode! >= 400) {
      return Colors.red.withOpacity(0.05);
    }
    return Theme.of(context).cardTheme.color ?? Colors.white;
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // 供应商图标
        SizedBox(
          width: 24,
          height: 24,
          child: SvgImage(
            assetPath: 'assets/images/${log.providerId.name}.svg',
            width: 48,
            height: 48,
          ),
        ),
        const SizedBox(width: 8),

        // API类型和状态码
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: log.apiType.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                TextSpan(
                  text: '${log.statusCode ?? 'N/A'}',
                  style: TextStyle(color: _getStatusCodeColor(), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),

        // 耗时
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getDurationColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getDurationColor().withOpacity(0.3)),
          ),
          child: Text(
            '${log.duration}ms',
            style: TextStyle(color: _getDurationColor(), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Color _getStatusCodeColor() {
    if (log.statusCode == null) return Colors.grey;
    if (log.statusCode! >= 200 && log.statusCode! < 300) return Colors.green;
    if (log.statusCode! >= 400 && log.statusCode! < 500) return Colors.orange;
    return Colors.red;
  }

  Color _getDurationColor() {
    if (log.duration < 500) return Colors.green;
    if (log.duration < 2000) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStatusInfo(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            log.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          ),
        ),
        if (log.retryCount != null && log.retryCount! > 0) ...[
          const SizedBox(width: 8),
          Chip(
            label: Text('${log.retryCount}次重试'),
            visualDensity: VisualDensity.compact,
            labelStyle: const TextStyle(fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildTimingInfo(BuildContext context) {
    return Row(
      children: [
        Text(
          DateFormat('HH:mm:ss.SSS').format(log.requestTime),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const Spacer(),
        if (log.errorMessage != null)
          Flexible(
            child: Text(
              log.errorMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.red[600], fontSize: 12),
            ),
          ),
      ],
    );
  }
}
