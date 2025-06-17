// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/dynamic_panel_ctrl/dynamic_panel_ctrl.dart
// Purpose:     dynamic panel ctrl
// Author:      songhuabiao
// Created:     2025-06-17 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/dynamic_panel_ctrl/dynamic_panel_layout.dart';
import 'package:irich/components/dynamic_panel_ctrl/dynamic_panel.dart';

class RichWidgetLayoutCtrl extends ConsumerStatefulWidget {
  const RichWidgetLayoutCtrl({super.key});

  @override
  ConsumerState<RichWidgetLayoutCtrl> createState() => _RichWidgetLayoutState();
}

class _RichWidgetLayoutState extends ConsumerState<RichWidgetLayoutCtrl> {
  final DynamicPanelLayout controller = DynamicPanelLayout();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildPanel(controller.root, constraints.biggest);
      },
    );
  }

  Widget _buildPanel(DynamicPanel panel, Size availableSize) {
    final screenRect = _denormalizeRect(panel.rect, availableSize);
    return Positioned(
      left: screenRect.left,
      top: screenRect.top,
      width: screenRect.width,
      height: screenRect.height,
      child: GestureDetector(
        onTap: () => controller.selectPanel(panel),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: controller.selectedPanel?.id == panel.id ? Colors.blue : Colors.grey,
              width: 2,
            ),
          ),
          child: _buildPanelWidgets(panel, availableSize),
        ),
      ),
    );
  }

  Widget _buildPanelWidgets(DynamicPanel panel, Size availableSize) {
    if (panel.type == DynamicPanelType.leaf) {
      return panel.widget ?? DefaultPanel(content: '空面板');
    }

    return Stack(
      children: [
        // 子面板
        ...panel.children.map((child) => _buildPanel(child, availableSize)),
        // 分割线交互区域
        ..._buildDividerHandles(panel, availableSize),
      ],
    );
  }

  List<Widget> _buildDividerHandles(DynamicPanel panel, Size availableSize) {
    if (panel.type == DynamicPanelType.leaf) return [];

    final handles = <Widget>[];
    final isRow = panel.type == DynamicPanelType.row;

    for (int i = 0; i < panel.children.length - 1; i++) {
      final child = panel.children[i];
      final screenRect = _denormalizeRect(child.rect, availableSize);

      handles.add(
        Positioned(
          left: isRow ? screenRect.right - 2 : 0,
          top: isRow ? 0 : screenRect.bottom - 2,
          width: isRow ? 4 : screenRect.width,
          height: isRow ? screenRect.height : 4,
          child: MouseRegion(
            cursor: isRow ? SystemMouseCursors.resizeLeftRight : SystemMouseCursors.resizeUpDown,
            child: GestureDetector(
              onPanUpdate: (details) {
                _handleDividerDrag(panel, i, details.delta, availableSize);
              },
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
      );
    }

    return handles;
  }

  void _handleDividerDrag(DynamicPanel panel, int dividerIndex, Offset delta, Size availableSize) {
    final isRow = panel.type == 'row';
    final deltaValue = isRow ? delta.dx : delta.dy;
    if (deltaValue == 0) return;

    final newState = DynamicPanel.deepCopy(controller.root);
    final targetPanel = _findPanel(newState, panel.id);
    if (targetPanel == null) return;

    final firstChild = targetPanel.children[dividerIndex];
    final secondChild = targetPanel.children[dividerIndex + 1];

    if (isRow) {
      final newWidth = firstChild.rect.width + deltaValue / availableSize.width;
      if (newWidth > 0.1 && secondChild.rect.width - deltaValue > 0.1) {
        firstChild.rect = firstChild.rect.copyWith(right: firstChild.rect.left + newWidth);
        secondChild.rect = secondChild.rect.copyWith(
          left: secondChild.rect.left + deltaValue / availableSize.width,
        );
      }
    } else {
      final newHeight = firstChild.rect.height + deltaValue / availableSize.height;
      if (newHeight > 0.1 && secondChild.rect.height - deltaValue > 0.1) {
        firstChild.rect = firstChild.rect.copyWith(bottom: firstChild.rect.top + newHeight);
        secondChild.rect = secondChild.rect.copyWith(
          top: secondChild.rect.top + deltaValue / availableSize.height,
        );
      }
    }

    controller.history.push(newState);
  }

  DynamicPanel? _findPanel(DynamicPanel current, int id) {
    if (current.id == id) return current;
    for (final child in current.children) {
      final found = _findPanel(child, id);
      if (found != null) return found;
    }
    return null;
  }

  Rect _denormalizeRect(Rect normalizedRect, Size availableSize) {
    return Rect.fromLTWH(
      normalizedRect.left * availableSize.width,
      normalizedRect.top * availableSize.height,
      normalizedRect.width * availableSize.width,
      normalizedRect.height * availableSize.height,
    );
  }
}

class DefaultPanel extends StatelessWidget {
  final String content;

  const DefaultPanel({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.orange.withOpacity(0.3),
      child: Center(child: Text(content, style: TextStyle(fontSize: 24))),
    );
  }
}
