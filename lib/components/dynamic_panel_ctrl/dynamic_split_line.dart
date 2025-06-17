// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/dynamic_panel_ctrl/dynamic_split_line.dart
// Purpose:     split line for dynamic panel
// Author:      songhuabiao
// Created:     2025-06-17 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

enum SplitMode { none, horizontal, vertical, cols_3, rows_3, grid_2_2, grid_4_4 }

class DynamicSplitLine {
  final bool isHorizontal; // true: 横向, false: 竖向
  double position; // 横向线: y坐标; 竖向线: x坐标
  double start; // 起点 (横向: x_min; 竖向: y_min)
  double end; // 终点 (横向: x_max; 竖向: y_max)

  DynamicSplitLine({
    required this.isHorizontal,
    required this.position,
    required this.start,
    required this.end,
  });
}
