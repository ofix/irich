// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/dynamic_panel_ctrl/dynamic_panel_chart.dart
// Purpose:     dynamic panel chart
// Author:      songhuabiao
// Created:     2025-06-18 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/dynamic_panel_ctrl/dynamic_panel_layout.dart';
import 'package:irich/components/dynamic_panel_ctrl/dynamic_panel_painter.dart';

class DynamicPanelChart extends ConsumerStatefulWidget {
  final double width;
  final double height;
  final DynamicPanelLayout layout;
  const DynamicPanelChart({
    super.key,
    required this.width,
    required this.height,
    required this.layout,
  });

  @override
  ConsumerState<DynamicPanelChart> createState() => _DynamicPanelChartState();
}

class _DynamicPanelChartState extends ConsumerState<DynamicPanelChart> {
  @override
  Widget build(BuildContext context) {
    final state = widget.layout;
    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color.fromARGB(255, 24, 24, 24 /*28, 29, 33*/),
      child: CustomPaint(
        size: Size(widget.width, widget.height),
        painter: DynamicPanelPainter(
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
