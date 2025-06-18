// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/dynamic_panel_ctrl/dynamic_split_line.dart
// Purpose:     split line for dynamic panel
// Author:      songhuabiao
// Created:     2025-06-17 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

enum SplitMode {
  none,
  horizontal,
  vertical,
  cols_3,
  rows_3,
  grid_2_2,
  grid_4_4;

  String get name {
    switch (this) {
      case SplitMode.none:
        return 'none';
      case SplitMode.horizontal:
        return 'horizontal';
      case SplitMode.vertical:
        return 'vertical';
      case SplitMode.cols_3:
        return 'cols_3';
      case SplitMode.rows_3:
        return 'rows_3';
      case SplitMode.grid_2_2:
        return 'grid_2x2';
      case SplitMode.grid_4_4:
        return 'grid_4x4';
    }
  }
}

class DynamicSplitLine {
  final bool isHorizontal; // true: 横向, false: 竖向
  double position; // 横向线: y坐标; 竖向线: x坐标
  double start; // 起点 (横向: x_min; 竖向: y_min)
  double end; // 终点 (横向: x_max; 竖向: y_max)
  bool isSelected; // 是否用户当前选中

  DynamicSplitLine({
    required this.isHorizontal,
    required this.position,
    required this.start,
    required this.end,
    this.isSelected = false,
  });
}
