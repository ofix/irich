// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/split_panel_ctrl/split_panel_layout.dart
// Purpose:     split panel layout
// Author:      songhuabiao
// Created:     2025-06-17 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:irich/components/split_panel_ctrl/split_panel.dart';
import 'package:irich/components/split_panel_ctrl/split_panel_ctrl.dart';

// 布局管理器
class SplitPanelLayout with ChangeNotifier {
  late SplitPanel _root; // 面板树根节点
  SplitPanel? _selectedPanel; // 当前选中的面板
  SplitLine? _selectedSplitLine; // 当前选中的分割线
  final OperationHistory _history = OperationHistory(); // 操作历史
  final List<SplitLine> _horizontalLines = []; // 横向分割线列表
  final List<SplitLine> _verticalLines = []; // 竖向分割线列表
  bool _layoutDirty = false; // 是否需要重新布局
  static int panelId = 0;

  // 公共属性
  List<SplitLine> get horizontalLines => _horizontalLines;
  List<SplitLine> get verticalLines => _verticalLines;
  SplitPanel get root => _root;
  SplitPanel? get selectedPanel => _selectedPanel;
  SplitLine? get activeSplitLine => _selectedSplitLine;
  OperationHistory get history => _history;

  // 撤销/恢复
  void undo() => _updateState(_history.undo);
  void redo() => _updateState(_history.redo);

  SplitPanelLayout() {
    _root = SplitPanel(rect: Rect.fromLTWH(0, 0, 1, 1), percent: 1);
    _root.parent = null;
    _selectedPanel = _root;
    _layoutDirty = true;
  }

  // 添加分割线（自动排序）
  void addSplitLine(SplitLine line) {
    final lines = line.isHorizontal ? _horizontalLines : _verticalLines;
    lines.add(line);
    _sortSplitLines(lines);
    // 动态调整占比
  }

  // 删除分割线
  void removeSplitLine(SplitLine line) {
    final lines = line.isHorizontal ? _horizontalLines : _verticalLines;
    lines.remove(line);
  }

  // 对分割线列表按照坐标大小进行排序
  void _sortSplitLines(List<SplitLine> lines) {
    lines.sort((a, b) => a.position.compareTo(b.position));
  }

  void onSplitLinesHitTest(Offset mousePos) {
    final line = hitTestSplitLines(mousePos.dx, mousePos.dy);
    if (line != null) {
      if (_selectedSplitLine != null) {
        _selectedSplitLine!.isSelected = false; // 取消上次的选中分割线
      }
      _selectedSplitLine = line;
      _selectedSplitLine!.isSelected = true;
    } else {
      if (_selectedSplitLine != null) {
        _selectedSplitLine!.isSelected = false; // 取消上次的选中分割线
        _selectedSplitLine = null;
      }
    }
  }

  // 查询点击是否选中某条线（threshold: 点击容差，左右/上下3个像素）
  SplitLine? hitTestSplitLines(double mouseX, double mouseY, {double threshold = 3.0}) {
    // 优先检查横向线
    final horizontalLine = _findNearestLine(
      lines: _horizontalLines,
      mousePos: mouseY,
      isHorizontal: true,
      mouseOrthogonalPos: mouseX,
      threshold: threshold,
    );

    if (horizontalLine != null) return horizontalLine;

    // 若未找到横向线，检查竖向线
    return _findNearestLine(
      lines: _verticalLines,
      mousePos: mouseX,
      isHorizontal: false,
      mouseOrthogonalPos: mouseY,
      threshold: threshold,
    );
  }

  SplitLine? _findNearestLine({
    required List<SplitLine> lines,
    required double mousePos,
    required bool isHorizontal,
    required double mouseOrthogonalPos,
    required double threshold,
  }) {
    if (lines.isEmpty) return null;

    // 先找出所有在阈值范围内的候选线
    final candidates = _findAllLinesInThreshold(
      lines: lines,
      mousePos: mousePos,
      threshold: threshold,
    );

    // 从候选线中找出正交坐标匹配的线
    return _findBestMatchingLine(
      candidates: candidates,
      isHorizontal: isHorizontal,
      mousePos: mousePos,
      mouseOrthogonalPos: mouseOrthogonalPos,
    );
  }

  List<SplitLine> _findAllLinesInThreshold({
    required List<SplitLine> lines,
    required double mousePos,
    required double threshold,
  }) {
    // 使用二分查找找到可能范围内的所有线
    int low = 0;
    int high = lines.length - 1;
    final candidates = <SplitLine>[];

    // 查找左边界
    int left = lines.length;
    while (low <= high) {
      final mid = low + (high - low) ~/ 2;
      if (lines[mid].position >= mousePos - threshold) {
        left = mid;
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    // 查找右边界
    low = 0;
    high = lines.length - 1;
    int right = -1;
    while (low <= high) {
      final mid = low + (high - low) ~/ 2;
      if (lines[mid].position <= mousePos + threshold) {
        right = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    // 收集候选线
    if (left <= right) {
      for (int i = left; i <= right; i++) {
        candidates.add(lines[i]);
      }
    }

    return candidates;
  }

  SplitLine? _findBestMatchingLine({
    required List<SplitLine> candidates,
    required bool isHorizontal,
    required double mousePos,
    required double mouseOrthogonalPos,
  }) {
    // 找出正交坐标最匹配的线
    SplitLine? bestMatch;
    double minDistance = double.infinity;

    for (final line in candidates) {
      // 检查正交坐标是否在线段范围内
      if (mouseOrthogonalPos >= line.start && mouseOrthogonalPos <= line.end) {
        // 计算与鼠标位置的距离
        final distance = (line.position - mousePos).abs();
        if (distance < minDistance) {
          minDistance = distance;
          bestMatch = line;
        }
      }
    }

    return bestMatch;
  }

  void forceLayout(SplitPanel node, Rect newRect) {
    _layoutDirty = true;
    doLayout(node, newRect);
  }

  /// [line] 分割线
  /// [delta] 左右/上下分割线拖动的偏移量
  void dragSplitLine(SplitLine line, Offset delta) {
    // 水平分割线（调整上下面板, 垂直分割线（调整左右面板）
    _adjustPanelLayout(
      line: line,
      delta: line.isHorizontal ? delta.dy : delta.dx,
      primaryPanel: line.firstPanel,
      secondaryPanel: line.secondPanel,
      isHorizontal: line.isHorizontal,
    );
    _sortSplitLines(_horizontalLines);
    _sortSplitLines(_verticalLines);
  }

  /// 调整面板布局
  /// [line] 分割线
  /// [delta] 拖动偏移量
  /// [primaryPanel] 主面板（原firstPanel）
  /// [secondaryPanel] 次面板（原secondPanel）
  /// [isHorizontal] 是否为水平分割线
  void _adjustPanelLayout({
    required SplitLine line,
    required double delta,
    required SplitPanel primaryPanel,
    required SplitPanel secondaryPanel,
    required bool isHorizontal,
  }) {
    const minPanelSize = 0.0;
    // 获取父容器尺寸用于计算百分比
    final parentRect = primaryPanel.parent!.rect;

    // 1. 更新分割线位置（限制在有效范围内）
    final newPosition = (line.position + delta).clamp(
      isHorizontal ? primaryPanel.rect.top + minPanelSize : primaryPanel.rect.left + minPanelSize,
      isHorizontal
          ? secondaryPanel.rect.bottom - minPanelSize
          : secondaryPanel.rect.right - minPanelSize,
    );
    line.position = newPosition;

    // 2. 调整面板尺寸
    if (isHorizontal) {
      // 水平分割线调整上下面板高度
      primaryPanel.rect = primaryPanel.rect.copyWith(bottom: newPosition);
      secondaryPanel.rect = secondaryPanel.rect.copyWith(top: newPosition);
      // 更新上下面板高度占比
      primaryPanel.percent = primaryPanel.rect.height / parentRect.height;
      secondaryPanel.percent = secondaryPanel.rect.height / parentRect.height;
    } else {
      // 垂直分割线调整左右面板宽度
      primaryPanel.rect = primaryPanel.rect.copyWith(right: newPosition);
      secondaryPanel.rect = secondaryPanel.rect.copyWith(left: newPosition);
      // 更新左右面板宽度占比
      primaryPanel.percent = primaryPanel.rect.width / parentRect.width;
      secondaryPanel.percent = secondaryPanel.rect.width / parentRect.width;
    }

    // 3. 确定拖动方向用于递归更新
    final direction =
        delta > 0
            ? (isHorizontal ? DragDirection.bottom : DragDirection.right)
            : (isHorizontal ? DragDirection.top : DragDirection.left);

    // 递归更新子面板（针对容器类型面板）
    _recursiveUpdatePanel(primaryPanel, direction);
    _recursiveUpdatePanel(secondaryPanel, direction);
  }

  /// 递归更新面板及其子面板
  /// [panel] 当前要更新的面板
  /// [direction] 拖动方向
  void _recursiveUpdatePanel(SplitPanel panel, DragDirection direction) {
    // 叶子节点无需处理
    if (panel.isLeaf) return;

    // 根据面板类型决定布局方向
    final isColumn = panel.type == SplitType.column;
    // 判断是否为水平拖动（上下方向）
    final isHorizontalDrag = direction == DragDirection.top || direction == DragDirection.bottom;

    // 更新起始位置（列布局用top，行布局用left）
    double position = isColumn ? panel.rect.top : panel.rect.left;

    for (int i = 0; i < panel.children.length; i++) {
      final child = panel.children[i];

      if (isColumn) {
        if (!isHorizontalDrag) {
          // 列布局中的水平拖动：更新左上角X坐标和宽度
          child.rect = Rect.fromLTWH(
            panel.rect.left,
            child.rect.top,
            panel.rect.width,
            child.rect.height,
          );
        } else {
          // 列布局中的垂直拖动：按百分比更新左上角Y坐标和高度
          final newHeight = panel.rect.height * child.percent;
          child.rect = Rect.fromLTWH(panel.rect.left, position, child.rect.width, newHeight);
          position += newHeight;
        }
      } else {
        if (isHorizontalDrag) {
          // 行布局中的垂直拖动：只更新左上角Y坐标和高度
          child.rect = Rect.fromLTWH(
            child.rect.left,
            panel.rect.top,
            child.rect.width,
            panel.rect.height,
          );
        } else {
          // 行布局中的水平拖动：按百分比更新左上角X坐标和宽度
          final newWidth = panel.rect.width * child.percent;
          child.rect = Rect.fromLTWH(position, panel.rect.top, newWidth, child.rect.height);
          position += newWidth;
        }
      }

      // 调整分割线（分割线比分割的矩形少一个）
      if (i < panel.lines.length) {
        _updateSplitLinePosition(
          line: panel.lines[i],
          adjacentPanelRect: child.rect,
          isColumn: isColumn,
        );
      }

      // 递归更新子面板的子面板
      _recursiveUpdatePanel(child, direction);
    }
  }

  /// 更新分割线位置和边界
  /// [line] 要更新的分割线
  /// [adjacentPanelRect] 相邻面板的矩形区域
  /// [isColumn] 是否为列布局
  void _updateSplitLinePosition({
    required SplitLine line,
    required Rect adjacentPanelRect,
    required bool isColumn,
  }) {
    if (isColumn) {
      // 列布局：分割线位置在面板底部，边界为左右边
      line.position = adjacentPanelRect.bottom;
      line.start = adjacentPanelRect.left;
      line.end = adjacentPanelRect.right;
    } else {
      // 行布局：分割线位置在面板右侧，边界为上下边
      line.position = adjacentPanelRect.right;
      line.start = adjacentPanelRect.top;
      line.end = adjacentPanelRect.bottom;
    }
  }

  bool isPtInRect(Rect rect, Offset point) {
    return (point.dx >= rect.left &&
        point.dy <= rect.right &&
        point.dy >= rect.top &&
        point.dy <= rect.bottom);
  }

  /// 用户调整窗口尺寸的时候，需要同步递归更新整棵动态面板树的矩形大小
  /// [newRect] 新的窗口尺寸
  void doLayout(SplitPanel node, Rect newRect) {
    if (!_layoutDirty) return;

    double scaleX = newRect.width / node.rect.width;
    double scaleY = newRect.height / node.rect.height;
    Rect oldRect = node.rect;
    node.rect = newRect;
    // 2. 递归更新子节点
    _doLayoutChildren(node, newRect);

    // // 3. 更新横向分割线
    // for (final line in _horizontalLines) {
    //   if (line != _selectedSplitLine) {
    //     Offset ptStart = Offset(line.start, line.position);
    //     Offset ptEnd = Offset(line.end, line.position);
    //     if (isPtInRect(oldRect, ptStart) && isPtInRect(oldRect, ptEnd)) {
    //       line.start *= scaleX;
    //       line.end *= scaleX;
    //       line.position *= scaleY;
    //     }
    //   }
    // }
    // // 4. 更新竖向分割线
    // for (final line in _verticalLines) {
    //   if (line != _selectedSplitLine) {
    //     Offset ptStart = Offset(line.position, line.start);
    //     Offset ptEnd = Offset(line.position, line.end);
    //     if (isPtInRect(oldRect, ptStart) && isPtInRect(oldRect, ptEnd)) {
    //       line.start *= scaleY;
    //       line.end *= scaleY;
    //       line.position *= scaleX;
    //     }
    //   }
    // }

    _sortSplitLines(_horizontalLines);
    _sortSplitLines(_verticalLines);
    _layoutDirty = false;
  }

  void _doLayoutChildren(SplitPanel node, Rect newRect) {
    if (node.type == SplitType.row) {
      double percent = 0;
      for (final child in node.children) {
        // 计算新的物理坐标
        Rect childNewRect = Rect.fromLTRB(
          newRect.left + percent * newRect.width,
          newRect.top,
          newRect.width * child.percent,
          newRect.height,
        );
        child.rect = childNewRect;
        percent += child.percent;

        // 递归处理子节点
        if (!child.isLeaf) {
          _doLayoutChildren(child, childNewRect);
        }
      }
    } else if (node.type == SplitType.column) {
      double percent = 0;
      for (final child in node.children) {
        // 计算新的物理坐标
        Rect childNewRect = Rect.fromLTRB(
          newRect.left,
          newRect.top + percent * newRect.height,
          newRect.width,
          newRect.height * child.percent,
        );
        child.rect = childNewRect;
        percent += child.percent;

        // 递归处理子节点
        if (!child.isLeaf) {
          _doLayoutChildren(child, childNewRect);
        }
      }
    }
  }

  void updateActiveSplitLine(Offset ptStart, Offset ptEnd) {
    if (_selectedSplitLine != null) {
      if (_selectedSplitLine!.isHorizontal) {
        _selectedSplitLine!.start = ptStart.dx;
        _selectedSplitLine!.end = ptEnd.dx;
        _selectedSplitLine!.position = ptEnd.dy;
      } else {
        _selectedSplitLine!.start = ptStart.dy;
        _selectedSplitLine!.end = ptEnd.dy;
        _selectedSplitLine!.position = ptEnd.dx;
      }
    }
    _sortSplitLines(_horizontalLines);
    _sortSplitLines(_verticalLines);
  }

  void onPanelSelected(Offset mousePos) {
    SplitPanel? target = findNearestPanelAtMousePos(root, mousePos);
    if (target != null) {
      _selectedPanel = target;
    }
  }

  /// 查找包含某点的最内层叶子节点
  /// [node] 面板树根节点
  /// [mousePos] 光标位置
  SplitPanel? findNearestPanelAtMousePos(SplitPanel node, Offset mousePos) {
    if (!node.rect.contains(mousePos)) return null;

    if (node.isLeaf) {
      return node;
    }

    // 按z-order反向遍历（后添加的面板优先）
    for (final child in node.children.reversed) {
      final result = findNearestPanelAtMousePos(child, mousePos);
      if (result != null) return result;
    }
    return null;
  }

  /// 查找与矩形相交的所有叶子节点
  /// [node] 面板树根节点
  /// [rect] 用户框选的矩形区域
  /// [panels] 相交的矩形区域
  void finalAllPanelsAtMousePos(SplitPanel node, Rect rect, List<SplitPanel> panels) {
    if (!node.rect.overlaps(rect)) return;

    if (node.isLeaf) {
      panels.add(node);
    } else {
      for (final child in node.children) {
        finalAllPanelsAtMousePos(child, rect, panels);
      }
    }
  }

  void _updateState(SplitPanel? state) {
    if (state != null) {
      _root = state;
      notifyListeners();
    }
  }

  // panel 绑定 Widget
  void bindWidget(SplitPanel current, Widget widget) {
    current.widget = widget;
  }

  /// 添加分割线
  /// [parentPanel] 添加分割线的父容器
  /// [mode] 分割模式
  /// 注意: 此函数必须在父容器完成分割后调用！！！
  void addSplitLines(SplitPanel parentPanel, SplitMode mode) {
    final rect = parentPanel.rect;

    switch (mode) {
      case SplitMode.horizontal:
        // 水平中心划分 - 添加一条水平分割线
        _addSingleSplitLine(
          parentPanel: parentPanel,
          isHorizontal: true,
          position: rect.top + rect.height / 2,
          start: rect.left,
          end: rect.right,
          firstChildIndex: 0,
          secondChildIndex: 1,
          targetList: _horizontalLines,
        );
        break;

      case SplitMode.vertical:
        // 垂直中心划分 - 添加一条垂直分割线
        _addSingleSplitLine(
          parentPanel: parentPanel,
          isHorizontal: false,
          position: rect.left + rect.width / 2,
          start: rect.top,
          end: rect.bottom,
          firstChildIndex: 0,
          secondChildIndex: 1,
          targetList: _verticalLines,
        );
        break;

      case SplitMode.cols_3:
        // 水平三等分 - 添加两条垂直分割线
        _addMultipleSplitLines(
          parentPanel: parentPanel,
          isHorizontal: false,
          positions: [rect.left + rect.width / 3, rect.left + rect.width * 2 / 3],
          start: rect.top,
          end: rect.bottom,
          childIndices: [0, 1, 2],
          targetList: _verticalLines,
        );
        break;

      case SplitMode.rows_3:
        // 垂直三等分 - 添加两条水平分割线
        _addMultipleSplitLines(
          parentPanel: parentPanel,
          isHorizontal: true,
          positions: [rect.top + rect.height / 3, rect.top + rect.height * 2 / 3],
          start: rect.left,
          end: rect.right,
          childIndices: [0, 1, 2],
          targetList: _horizontalLines,
        );
        break;

      case SplitMode.grid_2_2:
        // 修改为：一条水平线 + 两条居中垂直线
        _addGridSplitLines(parentPanel: parentPanel, cols: 2, rows: 2, rect: rect);
        break;

      case SplitMode.grid_4_4:
        // 修改为：三条水平线 + 上下三等分垂直线（共9条）
        _addComplexGridSplitLines(parentPanel: parentPanel, cols: 4, rows: 4, rect: rect);
        break;

      case SplitMode.none:
        // 不添加任何分割线
        break;
    }
  }

  /// 添加单条分割线
  void _addSingleSplitLine({
    required SplitPanel parentPanel,
    required bool isHorizontal,
    required double position,
    required double start,
    required double end,
    required int firstChildIndex,
    required int secondChildIndex,
    required List<SplitLine> targetList,
  }) {
    final splitLine = SplitLine(
      isHorizontal: isHorizontal,
      position: position,
      start: start,
      end: end,
      firstPanel: parentPanel.children[firstChildIndex],
      secondPanel: parentPanel.children[secondChildIndex],
    );

    targetList.add(splitLine);
    parentPanel.lines.add(splitLine);
  }

  /// 添加多条同方向分割线
  void _addMultipleSplitLines({
    required SplitPanel parentPanel,
    required bool isHorizontal,
    required List<double> positions,
    required double start,
    required double end,
    required List<int> childIndices,
    required List<SplitLine> targetList,
  }) {
    final lines = List<SplitLine>.generate(
      positions.length,
      (i) => SplitLine(
        isHorizontal: isHorizontal,
        position: positions[i],
        start: start,
        end: end,
        firstPanel: parentPanel.children[childIndices[i]],
        secondPanel: parentPanel.children[childIndices[i + 1]],
      ),
    );

    targetList.addAll(lines);
    parentPanel.lines.addAll(lines);
  }

  /// 添加2x2网格分割线
  void _addGridSplitLines({
    required SplitPanel parentPanel,
    required int cols,
    required int rows,
    required Rect rect,
  }) {
    // 水平分割线（1条）
    _addSingleSplitLine(
      parentPanel: parentPanel,
      isHorizontal: true,
      position: rect.top + rect.height / 2,
      start: rect.left,
      end: rect.right,
      firstChildIndex: 0,
      secondChildIndex: 1,
      targetList: _horizontalLines,
    );

    // 垂直分割线（2条）
    final verticalPosition = rect.left + rect.width / 2;
    final subHeight = rect.height / 2;

    for (int i = 0; i < rows; i++) {
      _addSingleSplitLine(
        parentPanel: parentPanel.children[i],
        isHorizontal: false,
        position: verticalPosition,
        start: rect.top + i * subHeight,
        end: rect.top + (i + 1) * subHeight,
        firstChildIndex: 0,
        secondChildIndex: 1,
        targetList: _verticalLines,
      );
    }
  }

  /// 添加4x4复杂网格分割线
  void _addComplexGridSplitLines({
    required SplitPanel parentPanel,
    required int cols,
    required int rows,
    required Rect rect,
  }) {
    // 水平分割线（3条）
    for (int i = 0; i < rows - 1; i++) {
      _addSingleSplitLine(
        parentPanel: parentPanel,
        isHorizontal: true,
        position: rect.top + rect.height * (i + 1) / rows,
        start: rect.left,
        end: rect.right,
        firstChildIndex: i,
        secondChildIndex: i + 1,
        targetList: _horizontalLines,
      );
    }

    // 垂直分割线 (12条)
    final subHeight = rect.height / rows;
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols - 1; j++) {
        _addSingleSplitLine(
          parentPanel: parentPanel.children[i],
          isHorizontal: false,
          position: rect.left + rect.width * (j + 1) / cols,
          start: rect.top + i * subHeight,
          end: rect.top + (i + 1) * subHeight,
          firstChildIndex: j,
          secondChildIndex: j + 1,
          targetList: _verticalLines,
        );
      }
    }
  }

  // 划分节点核心逻辑
  void splitPanel(SplitMode mode) {
    SplitPanel? panel = _selectedPanel;
    if (panel == null) return;
    panel.split(mode);
    // 添加分割线
    addSplitLines(panel, mode);
    _sortSplitLines(_horizontalLines);
    _sortSplitLines(_verticalLines);
    printSplitTree();
  }

  void printSplitTree() {
    final stack = Queue<(SplitPanel, int)>(); // (节点, 层级)
    stack.add((_root, 0));
    debugPrint("\n\n");
    while (stack.isNotEmpty) {
      final (node, level) = stack.removeLast();
      debugPrint(
        '${'  ' * level}${node.type.name} | ${node.pos} | ${node.percent} | ${node.rect.left.toInt()},${node.rect.top.toInt()},${node.rect.width.toInt()},${node.rect.height.toInt()}',
      ); // 按层级缩进

      // 子节点逆序入栈（保证从左到右遍历）
      for (var child in node.children.reversed) {
        stack.add((child, level + 1));
      }
    }
  }
}
