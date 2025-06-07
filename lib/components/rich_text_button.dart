// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/rich text button.dart
// Purpose:     custom text button
// Author:      songhuabiao
// Created:     2025-06-07 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';

class RichTextButton extends StatelessWidget {
  final String label; // 选项文字
  final bool isSelected; // 是否选中
  final VoidCallback onTap; // 点击回调
  final Color selectedColor; // 选中时的背景色（默认蓝色）
  final Color unselectedColor; // 未选中时的背景色（默认灰色）
  final Color textColor; // 文字颜色（默认白色）
  final double borderRadius; // 圆角半径（默认8）
  final double padding; // 内边距（默认12）

  const RichTextButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.selectedColor = const Color(0xFF525A65),
    this.unselectedColor = const Color(0xFF2E343B),
    this.textColor = const Color.fromARGB(255, 7, 232, 244),
    this.borderRadius = 0,
    this.padding = 8,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // 设置光标为可点击样式
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(borderRadius)),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                backgroundColor: Colors.transparent,
                color: isSelected ? textColor : const Color.fromARGB(255, 214, 211, 211),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
