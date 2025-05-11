// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/progress_popup.dart
// Purpose:     irich progress popup
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';

import 'package:flutter/material.dart';

class TaskProgress {
  final String name; // 任务名称
  final int current; // 当前
  final int total; // 总进度
  final String desc; // 描述
  TaskProgress({
    required this.name,
    required this.current,
    required this.total,
    required this.desc,
  });
}

// 显示下载进度弹窗
void showProgressPopup(BuildContext context, Stream<TaskProgress> stream) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0), // 调整圆角大小（默认是16.0）
          ),
          title: const Text('正在加载行情数据'),
          content: StreamBuilder<TaskProgress>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('下载失败: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              final progress = snapshot.data!;
              final textProgress =
                  "${(progress.current * 100 / progress.total).toStringAsFixed(2)}%";
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (progress.desc != "") Text("${progress.desc}, 进度：$textProgress"),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress.total > 0 ? progress.current / progress.total : null,
                    backgroundColor: Color(0xFFE8E8E8),
                    color: Color(0xFF1AA6FF),
                    minHeight: 8, // 进度条高度（默认4）
                  ),
                ],
              );
            },
          ),
        ),
  );
}

void hideProgressPopup(BuildContext context) {
  Navigator.of(context).pop(); // 关闭弹窗
}
