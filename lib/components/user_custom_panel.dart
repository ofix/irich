// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/user_custom_panel.dart
// Purpose:     user_custom_panel
// Author:      songhuabiao
// Created:     2025-07-04 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/split_view.dart';

class UserCustomPanel extends StatefulWidget {
  const UserCustomPanel({super.key});

  @override
  State<UserCustomPanel> createState() => _UserCustomPanelState();
}

class _UserCustomPanelState extends State<UserCustomPanel> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> json = {};
    return buildSplitViewFromJson(json);
  }

  Widget buildSplitViewFromJson(dynamic json) {
    if (json == null || json is! Map) return Container();

    final direction =
        json['direction'] == 'vertical' ? SplitDirection.vertical : SplitDirection.horizontal;

    final weights = List<double>.from(json['weights'] ?? []);
    final children = List<dynamic>.from(json['children'] ?? []);

    return SplitView(
      direction: direction,
      weights: weights,
      children:
          children.map((childJson) {
            if (childJson['type'] == 'panel') {
              // 创建面板
              return buildPanel(childJson);
            } else if (childJson['type'] == 'split') {
              // 递归创建分割视图
              return buildSplitViewFromJson(childJson);
            }
            return Container();
          }).toList(),
    );
  }

  // 构建面板组件
  Widget buildPanel(dynamic json) {
    final content = json['content'] ?? '';
    final color =
        json['color'] != null
            ? Color(int.parse(json['color'].replaceAll('#', '0xFF')))
            : Colors.grey;

    return Container(color: color, child: Center(child: Text(content)));
  }
}
