// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/ui/settings/task_list_panel.dart
// Purpose:     task list panel
// Author:      songhuabiao
// Created:     2025-05-18 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/service/tasks/task.dart';
import 'package:irich/store/state_tasks.dart';

class TaskListPanel extends ConsumerWidget {
  const TaskListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(stateTaskListProvider);
    final selectedTask = ref.watch(selectedTaskProvider);

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('任务列表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskListItem(
                key: ValueKey(task.taskId), // 确保每个任务项有唯一key
                task: task,
                isSelected: selectedTask?.taskId == task.taskId,
              );
            },
          ),
        ),
      ],
    );
  }
}

class TaskListItem extends ConsumerWidget {
  final Task task;
  final bool isSelected;

  const TaskListItem({super.key, required this.task, required this.isSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: isSelected ? Colors.blue[50] : null,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusIcon(task.status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.type.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('${(task.progress * 100).toStringAsFixed(2)}%'),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: task.progress,
                backgroundColor: Colors.grey[200],
                color: _getProgressColor(task.status),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Text(task.website, style: const TextStyle(fontSize: 12)),
                  // Text(
                  //   '速度: ${task.currentSpeed.toStringAsFixed(2)} KB/s',
                  //   style: const TextStyle(fontSize: 12),
                  // ),
                ],
              ),
              const SizedBox(height: 4),
              _buildActionButtons(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(TaskStatus status) {
    final icon = switch (status) {
      TaskStatus.pending => Icons.access_time,
      TaskStatus.running => Icons.play_arrow,
      TaskStatus.paused => Icons.pause,
      TaskStatus.completed => Icons.check_circle,
      TaskStatus.failed => Icons.error,
      TaskStatus.cancelled => Icons.cancel,
      TaskStatus.exit => throw UnimplementedError(),
      TaskStatus.unknown => throw UnimplementedError(),
    };

    final color = switch (status) {
      TaskStatus.pending => Colors.blue,
      TaskStatus.running => Colors.green,
      TaskStatus.paused => Colors.orange,
      TaskStatus.completed => Colors.green,
      TaskStatus.failed => Colors.red,
      TaskStatus.cancelled => Colors.grey,
      TaskStatus.exit => throw UnimplementedError(),
      TaskStatus.unknown => throw UnimplementedError(),
    };

    return Icon(icon, color: color, size: 20);
  }

  Color _getProgressColor(TaskStatus status) {
    return switch (status) {
      TaskStatus.failed => Colors.red,
      TaskStatus.cancelled => Colors.grey,
      _ => Colors.blue,
    };
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    final asyncScheduler = ref.watch(taskSchedulerProvider);

    return asyncScheduler.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
      data: (scheduler) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (task.status == TaskStatus.running)
              IconButton(
                icon: const Icon(Icons.pause, size: 20),
                onPressed: () => scheduler.pauseTask(task.taskId),
              ),
            if (task.status == TaskStatus.paused)
              IconButton(
                icon: const Icon(Icons.play_arrow, size: 20),
                onPressed: () => scheduler.resumeTask(task.taskId),
              ),
            IconButton(
              icon: const Icon(Icons.cancel, size: 20),
              onPressed: () => scheduler.cancelTask(task.taskId),
            ),
          ],
        );
      },
    );
  }
}
