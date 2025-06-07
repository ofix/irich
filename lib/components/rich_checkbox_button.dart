// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/rich_checkbox_button.dart
// Purpose:     custom checkbox button
// Author:      songhuabiao
// Created:     2025-06-07 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';

class RichCheckboxButton extends StatelessWidget {
  final String label; // 选项文字
  final bool isSelected; // 是否选中
  final VoidCallback onTap; // 点击回调
  final Color selectedColor; // 选中时的背景色（默认蓝色）
  final Color unselectedColor; // 未选中时的背景色（默认灰色）
  final double borderRadius; // 圆角半径（默认8）
  final double padding; // 内边距（默认12）
  final double height;

  const RichCheckboxButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.selectedColor = const Color.fromARGB(255, 43, 118, 224),
    this.unselectedColor = const Color(0xFF2E343B),
    this.borderRadius = 0,
    this.padding = 8,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // 设置光标为可点击样式
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          padding: EdgeInsets.fromLTRB(padding, 4, padding, 4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(borderRadius)),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                backgroundColor: Colors.transparent,
                color: isSelected ? selectedColor : unselectedColor,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
