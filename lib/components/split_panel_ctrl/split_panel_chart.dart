// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/split_panel_ctrl/split_panel_chart.dart
// Purpose:     split panel chart
// Author:      songhuabiao
// Created:     2025-06-18 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/split_panel_ctrl/split_panel_layout.dart';
import 'package:irich/components/split_panel_ctrl/split_panel_painter.dart';

class SplitPanelChart extends ConsumerStatefulWidget {
  final double width;
  final double height;
  final SplitPanelLayout layout;
  const SplitPanelChart({
    super.key,
    required this.width,
    required this.height,
    required this.layout,
  });

  @override
  ConsumerState<SplitPanelChart> createState() => _SplitPanelChartState();
}

class _SplitPanelChartState extends ConsumerState<SplitPanelChart> {
  @override
  Widget build(BuildContext context) {
    final state = widget.layout;
    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color.fromARGB(255, 24, 24, 24 /*28, 29, 33*/),
      child: CustomPaint(
        size: Size(widget.width, widget.height),
        painter: SplitPanelPainter(
          root: state.root,
          selectedPanel: state.selectedPanel,
          selectedSplitLine: state.activeSplitLine,
          horizontalLines: state.horizontalLines,
          verticalLines: state.verticalLines,
        ),
      ),
    );
  }
}
