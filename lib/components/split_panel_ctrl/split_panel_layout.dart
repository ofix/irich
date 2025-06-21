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

// 布局管理器
class SplitPanelLayout with ChangeNotifier {
  late SplitContainer _root; // 面板树根节点
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
  SplitContainer get root => _root;
  SplitPanel? get selectedPanel => _selectedPanel;
  SplitLine? get activeSplitLine => _selectedSplitLine;
  OperationHistory get history => _history;

  // 撤销/恢复
  void undo() => _updateState(_history.undo);
  void redo() => _updateState(_history.redo);

  SplitPanelLayout() {
    _root = SplitPanel(rect: Rect.fromLTWH(0, 0, 1, 1), percent: 1);
    _root.parent = null;
    _selectedPanel = _root as SplitPanel;
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

  void forceLayout(SplitContainer node, Rect newRect) {
    _layoutDirty = true;
    doLayout(node, newRect);
  }

  /// [line] 分割线
  /// [delta] 左右/上下分割线拖动的偏移量
  void dragSplitLine(SplitLine line, Offset delta) {
    // 获取关联的两个面板
    final firstPanel = line.firstPanel;
    final secondPanel = line.secondPanel;

    if (line.isHorizontal) {
      // 水平分割线（调整上下面板）
      _adjustVerticalLayout(
        line: line,
        delta: delta.dy,
        topPanel: firstPanel,
        bottomPanel: secondPanel,
      );
    } else {
      // 垂直分割线（调整左右面板）
      _adjustHorizontalLayout(
        line: line,
        delta: delta.dx,
        leftPanel: firstPanel,
        rightPanel: secondPanel,
      );
    }
    _sortSplitLines(_horizontalLines);
    _sortSplitLines(_verticalLines);
  }

  void _adjustVerticalLayout({
    required SplitLine line,
    required double delta,
    required SplitContainer topPanel,
    required SplitContainer bottomPanel,
  }) {
    final minPanelHeight = 0;
    // 1. 更新分割线位置（限制在有效范围内）
    final newY = (line.position + delta).clamp(
      topPanel.rect.top + minPanelHeight,
      bottomPanel.rect.bottom - minPanelHeight,
    );
    line.position = newY;

    // 2. 调整左右面板宽度
    topPanel.rect = topPanel.rect.copyWith(bottom: newY);
    bottomPanel.rect = bottomPanel.rect.copyWith(top: newY);

    // 4. 递归更新子面板（针对容器类型面板）
    // 3. 递归更新子面板
    _recursiveUpdatePanel(topPanel);
    _recursiveUpdatePanel(bottomPanel);
  }

  void _adjustHorizontalLayout({
    required SplitLine line,
    required double delta,
    required SplitContainer leftPanel,
    required SplitContainer rightPanel,
  }) {
    final minPanelWidth = 0;
    // 1. 更新分割线位置（限制在有效范围内）
    final newX = (line.position + delta).clamp(
      leftPanel.rect.left + minPanelWidth,
      rightPanel.rect.right - minPanelWidth,
    );
    line.position = newX;

    // 2. 调整左右面板宽度
    leftPanel.rect = leftPanel.rect.copyWith(right: newX);
    rightPanel.rect = rightPanel.rect.copyWith(left: newX);

    // 3. 递归更新子面板
    _recursiveUpdatePanel(leftPanel);
    _recursiveUpdatePanel(rightPanel);
  }

  void _recursiveUpdatePanel(SplitContainer panel) {
    if (panel is SplitPanel) return;
    // 根据面板 类型决定布局方向
    final isColumn = panel is SplitColumn;
    // 计算子面板的新边界
    double cursor = isColumn ? panel.rect.top : panel.rect.left;
    final totalFlex = panel.children.fold(0.0, (sum, child) => sum + child.percent);

    for (final child in panel.children) {
      final extent =
          (isColumn ? panel.rect.height : panel.rect.width) * (child.percent / totalFlex);
      // 更新子面板rect
      child.rect =
          isColumn
              ? Rect.fromLTWH(panel.rect.left, cursor, panel.rect.width, extent)
              : Rect.fromLTWH(cursor, panel.rect.top, extent, panel.rect.height);
      // 递归更新子面板的子面板
      _recursiveUpdatePanel(child);
      cursor += extent;
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
  void doLayout(SplitContainer node, Rect newRect) {
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

  void _doLayoutChildren(SplitContainer node, Rect newRect) {
    if (node is SplitRow) {
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
        if (child is! SplitPanel) {
          _doLayoutChildren(child, childNewRect);
        }
      }
    } else if (node is SplitColumn) {
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
        if (child is! SplitPanel) {
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
  SplitPanel? findNearestPanelAtMousePos(SplitContainer node, Offset mousePos) {
    if (!node.rect.contains(mousePos)) return null;

    if (node is SplitPanel) {
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
  void finalAllPanelsAtMousePos(SplitContainer node, Rect rect, List<SplitPanel> panels) {
    if (!node.rect.overlaps(rect)) return;

    if (node is SplitPanel) {
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

  /// 将父容器拆分成多个小矩形
  List<Rect> getSplitRects(Rect rect, SplitMode mode) {
    final rects = <Rect>[];

    switch (mode) {
      case SplitMode.horizontal:
        // 水平中心划分
        //  ----
        //  |  |
        //  ----
        //  |  |
        //  ----
        final subHeight = rect.height / 2;
        rects.add(Rect.fromLTWH(rect.left, rect.top, rect.width, subHeight));
        rects.add(Rect.fromLTWH(rect.left, rect.top + subHeight, rect.width, subHeight));
        break;

      case SplitMode.vertical:
        // 垂直中心划分
        //  |   |
        //  ----
        //  |   |
        //  ----
        final subWidth = rect.width / 2;
        rects.add(Rect.fromLTWH(rect.left, rect.top, subWidth, rect.height));
        rects.add(Rect.fromLTWH(rect.left + subWidth, rect.top, subWidth, rect.height));
        break;

      case SplitMode.cols_3:
        // 水平3等分
        //  |  |  |
        //  ---------
        //  |  |  |
        //  ---------
        final subWidth = rect.width / 3;
        rects.add(Rect.fromLTWH(rect.left, rect.top, subWidth, rect.height));
        rects.add(Rect.fromLTWH(rect.left + subWidth, rect.top, subWidth, rect.height));
        rects.add(Rect.fromLTWH(rect.left + subWidth * 2, rect.top, subWidth, rect.height));
        break;

      case SplitMode.rows_3:
        // 垂直3等分
        //  ----
        //  |  |
        //  ----
        //  |  |
        //  ----
        //  |  |
        //  ----
        final subHeight = rect.height / 3;
        rects.add(Rect.fromLTWH(rect.left, rect.top, rect.width, subHeight));
        rects.add(Rect.fromLTWH(rect.left, rect.top + subHeight, rect.width, subHeight));
        rects.add(Rect.fromLTWH(rect.left, rect.top + subHeight * 2, rect.width, subHeight));
        break;

      case SplitMode.grid_2_2:
        // 2x2网格
        //  |   |
        //  ----
        //  |   |
        final subWidth = rect.width / 2;
        final subHeight = rect.height / 2;
        for (int row = 0; row < 2; row++) {
          for (int col = 0; col < 2; col++) {
            rects.add(
              Rect.fromLTWH(
                rect.left + col * subWidth,
                rect.top + row * subHeight,
                subWidth,
                subHeight,
              ),
            );
          }
        }
        break;

      case SplitMode.grid_4_4:
        // 4x4网格
        final subWidth = rect.width / 4;
        final subHeight = rect.height / 4;
        for (int row = 0; row < 4; row++) {
          for (int col = 0; col < 4; col++) {
            rects.add(
              Rect.fromLTWH(
                rect.left + col * subWidth,
                rect.top + row * subHeight,
                subWidth,
                subHeight,
              ),
            );
          }
        }
        break;

      case SplitMode.none:
        // 不分割，返回原矩形
        rects.add(rect);
        break;
    }

    return rects;
  }

  SplitPanelType? getParentPanelType(SplitMode mode) {
    if (mode == SplitMode.horizontal) {
      return SplitPanelType.column;
    } else if (mode == SplitMode.vertical) {
      return SplitPanelType.row;
    } else if (mode == SplitMode.cols_3) {
      return SplitPanelType.row;
    } else if (mode == SplitMode.rows_3) {
      return SplitPanelType.column;
    } else if (mode == SplitMode.grid_2_2) {
      return SplitPanelType.row;
    } else if (mode == SplitMode.grid_4_4) {
      return SplitPanelType.row;
    }
    return null;
  }

  /// 添加分割线
  /// [parentPanel] 添加分割线的父容器
  /// [mode] 分割模式
  /// 注意: 此函数必须在父容器完成分割后调用！！！
  void addSplitLines(SplitContainer parentPanel, SplitMode mode) {
    Rect rect = parentPanel.rect;
    switch (mode) {
      case SplitMode.horizontal:
        // 水平中心划分 - 添加一条水平分割线
        final splitLine = SplitLine(
          isHorizontal: true,
          position: rect.top + rect.height / 2,
          start: rect.left,
          end: rect.right,
          firstPanel: parentPanel.children[0],
          secondPanel: parentPanel.children[1],
        );
        _horizontalLines.add(splitLine);
        if (parentPanel is SplitRow || parentPanel is SplitColumn) {
          parentPanel.lines.add(splitLine);
        }
        break;

      case SplitMode.vertical:
        // 垂直中心划分 - 添加一条垂直分割线
        final splitLine = SplitLine(
          isHorizontal: false,
          position: rect.left + rect.width / 2,
          start: rect.top,
          end: rect.bottom,
          firstPanel: parentPanel.children[0],
          secondPanel: parentPanel.children[1],
        );
        _verticalLines.add(splitLine);
        parentPanel.lines.add(splitLine);
        break;

      case SplitMode.cols_3:
        // 水平三等分 - 添加两条垂直分割线
        final splitLine1 = SplitLine(
          isHorizontal: false,
          position: rect.left + rect.width / 3,
          start: rect.top,
          end: rect.bottom,
          firstPanel: parentPanel.children[0],
          secondPanel: parentPanel.children[1],
        );
        final splitLine2 = SplitLine(
          isHorizontal: false,
          position: rect.left + rect.width * 2 / 3,
          start: rect.top,
          end: rect.bottom,
          firstPanel: parentPanel.children[1],
          secondPanel: parentPanel.children[2],
        );
        verticalLines.addAll([splitLine1, splitLine2]);
        parentPanel.lines.addAll([splitLine1, splitLine2]);
        break;

      case SplitMode.rows_3:
        // 垂直三等分 - 添加两条水平分割线
        final splitLine1 = SplitLine(
          isHorizontal: true,
          position: rect.top + rect.height / 3,
          start: rect.left,
          end: rect.right,
          firstPanel: parentPanel.children[0],
          secondPanel: parentPanel.children[1],
        );
        final splitLine2 = SplitLine(
          isHorizontal: true,
          position: rect.top + rect.height * 2 / 3,
          start: rect.left,
          end: rect.right,
          firstPanel: parentPanel.children[1],
          secondPanel: parentPanel.children[2],
        );
        _horizontalLines.addAll([splitLine1, splitLine2]);
        break;

      case SplitMode.grid_2_2:
        // 修改为：一条水平线 + 两条居中垂直线
        _horizontalLines.add(
          SplitLine(
            isHorizontal: true,
            position: rect.top + rect.height / 2,
            start: rect.left,
            end: rect.right,
            firstPanel: parentPanel.children[0],
            secondPanel: parentPanel.children[1],
          ),
        );
        _verticalLines.addAll([
          SplitLine(
            isHorizontal: false,
            position: rect.left + rect.width / 2,
            start: rect.top,
            end: rect.top + rect.height / 2,
            firstPanel: parentPanel.children[0].children[0],
            secondPanel: parentPanel.children[0].children[1],
          ),
          SplitLine(
            isHorizontal: false,
            position: rect.left + rect.width / 2,
            start: rect.top + rect.height / 2,
            end: rect.bottom,
            firstPanel: parentPanel.children[1].children[0],
            secondPanel: parentPanel.children[1].children[1],
          ),
        ]);
        break;

      case SplitMode.grid_4_4:
        // 修改为：三条水平线 + 上下三等分垂直线（共9条）
        // 水平分割线（3条）
        for (int i = 0; i < 3; i++) {
          _horizontalLines.add(
            SplitLine(
              isHorizontal: true,
              position: rect.top + rect.height * (i + 1) / 4,
              start: rect.left,
              end: rect.right,
              firstPanel: parentPanel.children[i],
              secondPanel: parentPanel.children[i + 1],
            ),
          );
        }
        // 垂直分割线 (12条)
        double subHeight = rect.height / 4;
        for (int i = 0; i < 4; i++) {
          for (int j = 0; j < 3; j++) {
            _verticalLines.add(
              SplitLine(
                isHorizontal: false,
                position: rect.left + rect.width * (j + 1) / 4,
                start: rect.top + i * subHeight,
                end: rect.top + (i + 1) * subHeight,
                firstPanel: parentPanel.children[i].children[j],
                secondPanel: parentPanel.children[i].children[j + 1],
              ),
            );
          }
        }
        break;

      case SplitMode.none:
        // 不添加任何分割线
        break;
    }
  }

  // 划分节点核心逻辑
  void splitPanel(SplitMode mode) {
    SplitPanel? panel = _selectedPanel;
    if (panel == null) {
      return;
    }
    // 只能对叶子节点进行分割
    List<Rect> splitRects = getSplitRects(panel.rect, mode);
    // 添加所有子面板
    SplitContainer newPanel = addSplitSubPanels(panel, mode, splitRects);
    // 添加分割线
    addSplitLines(newPanel, mode);
    _sortSplitLines(_horizontalLines);
    _sortSplitLines(_verticalLines);
    printSplitTree();
  }

  int _getSplitCount(SplitMode mode) {
    return switch (mode) {
      SplitMode.horizontal || SplitMode.vertical => 2,
      SplitMode.rows_3 || SplitMode.cols_3 => 3,
      SplitMode.grid_2_2 => 4,
      SplitMode.grid_4_4 => 16,
      _ => throw ArgumentError('Unsupported split mode: $mode'),
    };
  }

  double _getChildPercent(SplitMode mode) {
    return switch (mode) {
      SplitMode.horizontal || SplitMode.vertical => 0.5,
      SplitMode.rows_3 || SplitMode.cols_3 => 1 / 3,
      SplitMode.grid_2_2 => 0.5,
      SplitMode.grid_4_4 => 0.25,
      _ => throw ArgumentError('Unsupported split mode: $mode'),
    };
  }

  void printSplitTree() {
    final stack = Queue<(SplitContainer, int)>(); // (节点, 层级)
    stack.add((_root, 0));

    while (stack.isNotEmpty) {
      final (node, level) = stack.removeLast();
      debugPrint('${'  ' * level}${node.name} -- ${node.pos}'); // 按层级缩进

      // 子节点逆序入栈（保证从左到右遍历）
      for (var child in node.children.reversed) {
        stack.add((child, level + 1));
      }
    }
  }

  SplitContainer addSplitSubPanels(SplitPanel parent, SplitMode mode, List<Rect> rects) {
    final splitCount = _getSplitCount(mode);
    final childPercent = _getChildPercent(mode);

    SplitContainer splitContainer = _createSplitContainer(mode, parent.rect);
    final children = _createChildPanels(parent, splitCount, childPercent, rects, mode);

    splitContainer.children.addAll(children);
    _assignPositions(children, splitContainer);

    final grandParent = parent.parent;
    replaceSplitPanel(splitContainer, grandParent, parent.pos);
    return splitContainer;
  }

  SplitContainer _createSplitContainer(SplitMode mode, Rect rect) {
    return switch (mode) {
      SplitMode.horizontal || SplitMode.rows_3 => SplitColumn(rect: rect),
      SplitMode.vertical || SplitMode.cols_3 => SplitRow(rect: rect),
      SplitMode.grid_2_2 || SplitMode.grid_4_4 => SplitRow(rect: rect),
      _ => throw ArgumentError('Unsupported split mode: $mode'),
    };
  }

  List<SplitContainer> _createChildPanels(
    SplitPanel parent,
    int splitCount,
    double childPercent,
    List<Rect> rects,
    SplitMode mode,
  ) {
    if (mode == SplitMode.grid_2_2 || mode == SplitMode.grid_4_4) {
      return _createGridPanels(parent, splitCount, rects, mode);
    }

    return List.generate(splitCount, (index) {
      return SplitPanel(
        rect: rects[index],
        percent: childPercent,
        widget: index == 0 ? parent.widget : null,
        groupId: parent.groupId,
      );
    });
  }

  List<SplitContainer> _createGridPanels(
    SplitPanel parent,
    int splitCount,
    List<Rect> rects,
    SplitMode mode,
  ) {
    final rows = _getGridRows(mode);
    final rowCount = rows;
    final colCount = rows;
    final rowHeight = parent.rect.height / rowCount;
    final rowPercent = parent.percent / rowCount;

    final List<SplitContainer> rowPanels = [];

    for (int row = 0; row < rowCount; row++) {
      final top = parent.rect.top + row * rowHeight;
      final startIndex = row * colCount;
      final rowRects = rects.sublist(startIndex, startIndex + colCount);

      final rowPanel = _createRowPanel(
        parent: parent,
        top: top,
        height: rowHeight,
        percent: rowPercent,
        childrenRects: rowRects,
        hasWidget: row == 0,
      );
      rowPanels.add(rowPanel);
    }

    return rowPanels;
  }

  int _getGridRows(SplitMode mode) {
    return switch (mode) {
      SplitMode.grid_2_2 => 2,
      SplitMode.grid_4_4 => 4,
      _ => throw ArgumentError('Not a grid mode: $mode'),
    };
  }

  void _assignPositions(List<SplitContainer> panels, SplitContainer newParent) {
    for (int i = 0; i < panels.length; i++) {
      panels[i].pos = i;
      panels[i].parent = newParent;
    }
  }

  void replaceSplitPanel(SplitContainer newContainer, SplitContainer? grandParent, int pos) {
    if (grandParent == null) {
      _root = newContainer;
    } else {
      grandParent.children[pos] = newContainer;
    }
  }

  SplitContainer _createRowPanel({
    required SplitPanel parent,
    required double top,
    required double height,
    required double percent,
    required List<Rect> childrenRects,
    required bool hasWidget,
  }) {
    List<SplitContainer> subPanels = [];
    final childPercent = percent / childrenRects.length;

    for (int i = 0; i < childrenRects.length; i++) {
      final panel = SplitPanel(
        rect: childrenRects[i],
        percent: childPercent,
        widget: hasWidget && i == 0 ? parent.widget : null,
        groupId: parent.groupId,
      );
      subPanels.add(panel);
    }
    final splitRow = SplitRow(
      rect: Rect.fromLTWH(parent.rect.left, top, parent.rect.width, height),
      percent: percent,
      children: subPanels,
    );
    _assignPositions(subPanels, splitRow);
    return splitRow;
  }
}
