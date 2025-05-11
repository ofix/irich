// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/desktop_app_bar.dart
// Purpose:     desktop app bar
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';

class DesktopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DesktopAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      // color: Color.fromARGB(255, 24, 22, 22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          // 品牌Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FlutterLogo(size: 32),
          ),
          // 顶部菜单项
          _buildMenuButton(context, '文件'),
          _buildMenuButton(context, '编辑'),
          _buildMenuButton(context, '查看'),
          _buildMenuButton(context, '帮助'),
          const Spacer(),
          // 右侧控制按钮
          _buildWindowControlButton(Icons.minimize),
          _buildWindowControlButton(Icons.crop_square),
          _buildWindowControlButton(Icons.close),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String text) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: () {},
      child: Text(text),
    );
  }

  Widget _buildWindowControlButton(IconData icon) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(icon: Icon(icon, size: 16), onPressed: () {}),
    );
  }
}
