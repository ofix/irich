// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/text radio button.dart
// Purpose:     text radio button
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';

class TextRadioButton extends StatelessWidget {
  final String label; // 选项文字
  final bool isSelected; // 是否选中
  final VoidCallback onTap; // 点击回调
  final Color selectedColor; // 选中时的背景色（默认蓝色）
  final Color unselectedColor; // 未选中时的背景色（默认灰色）
  final Color textColor; // 文字颜色（默认白色）
  final double borderRadius; // 圆角半径（默认8）
  final double padding; // 内边距（默认12）

  const TextRadioButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.selectedColor = const Color(0xFF525A65),
    this.unselectedColor = const Color(0xFF2E343B),
    this.textColor = Colors.white,
    this.borderRadius = 0,
    this.padding = 8,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: padding),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: isSelected ? textColor : Colors.black, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
