// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/desktop_layout.dart
// Purpose:     irich desktop layout
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'desktop_app_bar.dart';
import 'desktop_menu.dart';

class DesktopLayout extends StatelessWidget {
  final Widget child;

  const DesktopLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null, // 禁用默认AppBar
      body: Column(
        children: [
          // 顶部菜单栏 (macOS风格)
          const DesktopAppBar(),
          // 主内容区
          Expanded(
            child: Row(
              children: [
                // 左侧固定菜单
                const DesktopMenu(),
                // 内容区域
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
