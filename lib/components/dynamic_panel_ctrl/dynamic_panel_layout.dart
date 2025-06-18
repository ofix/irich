// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/dynamic_panel_ctrl/dynamic_panel_layout.dart
// Purpose:     dynamic panel layout
// Author:      songhuabiao
// Created:     2025-06-17 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/dynamic_panel_ctrl/dynamic_panel.dart';
import 'package:irich/components/dynamic_panel_ctrl/dynamic_split_line.dart';

// 布局管理器
class DynamicPanelLayout with ChangeNotifier {
  late DynamicPanel _root; // 面板树根节点
  DynamicPanel? _selectedPanel; // 当前选中的面板
  DynamicSplitLine? _selectedSplitLine; // 当前选中的分割线
  SplitMode _splitMode = SplitMode.none; // 当前分割
  final OperationHistory _history = OperationHistory(); // 操作历史
  final List<DynamicSplitLine> _horizontalLines = []; // 横向分割线列表
  final List<DynamicSplitLine> _verticalLines = []; // 竖向分割线列表
  bool _layoutDirty = false; // 是否需要重新布局
  Rect _boundary = Rect.fromLTWH(0, 0, 1, 1); // 父容器边界
  static int panelId = 0;

  // 公共属性
  List<DynamicSplitLine> get horizontalLines => _horizontalLines;
  List<DynamicSplitLine> get verticalLines => _verticalLines;
  DynamicPanel get root => _root;
  DynamicPanel? get selectedPanel => _selectedPanel;
  DynamicSplitLine? get activeSplitLine => _selectedSplitLine;
  OperationHistory get history => _history;

  // 撤销/恢复
  void undo() => _updateState(_history.undo);
  void redo() => _updateState(_history.redo);

  DynamicPanelLayout() {
    _root = DynamicPanel(rect: Rect.fromLTWH(0, 0, 1, 1), id: panelId++);
    _selectedPanel = _root;
    _boundary = Rect.fromLTWH(0, 0, 1, 1);
    _layoutDirty = true;
  }

  // 添加分割线（自动排序）
  void addSplitLine(DynamicSplitLine line) {
    final lines = line.isHorizontal ? _horizontalLines : _verticalLines;
    lines.add(line);
    _sortSplitLines(lines);
    // 动态调整占比
  }

  // 删除分割线
  void removeSplitLine(DynamicSplitLine line) {
    final lines = line.isHorizontal ? _horizontalLines : _verticalLines;
    lines.remove(line);
  }

  // 移动分割线，并限制范围
  void moveLine(DynamicSplitLine line, double newPosition) {
    final lines = line.isHorizontal ? _horizontalLines : _verticalLines;
    final index = _findLineIndex(lines, line.position);
    if (index == -1) return;

    // 计算允许移动的最小/最大位置
    final (minPos, maxPos) = _calculateMovementRange(lines, index, line.isHorizontal);
    line.position = newPosition.clamp(minPos, maxPos);
    // 重新排序以保持有序
    _sortSplitLines(lines);
    // 动态调整占比
  }

  // 对分割线列表按照坐标大小进行排序
  void _sortSplitLines(List<DynamicSplitLine> lines) {
    lines.sort((a, b) => a.position.compareTo(b.position));
  }

  // 查询点击是否选中某条线（threshold: 点击容差，左右/上下3个像素）
  DynamicSplitLine? hitTestSplitLines(double mouseX, double mouseY, {double threshold = 3.0}) {
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

  // --- 私有方法 ---
  // 二分查找线位置对应的索引
  int _findLineIndex(List<DynamicSplitLine> lines, double position) {
    int left = 0, right = lines.length - 1;
    while (left <= right) {
      final mid = left + (right - left) ~/ 2;
      if (lines[mid].position == position) {
        return mid;
      } else if (lines[mid].position < position) {
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }
    return -1;
  }

  // 计算可移动范围
  (double, double) _calculateMovementRange(
    List<DynamicSplitLine> lines,
    int index,
    bool isHorizontal,
  ) {
    double minPos, maxPos;

    if (isHorizontal) {
      minPos = index > 0 ? lines[index - 1].position : _boundary.top;
      maxPos = index < lines.length - 1 ? lines[index + 1].position : _boundary.bottom;
    } else {
      minPos = index > 0 ? lines[index - 1].position : _boundary.left;
      maxPos = index < lines.length - 1 ? lines[index + 1].position : _boundary.right;
    }

    return (minPos, maxPos);
  }

  /// 用户调整窗口尺寸的时候，需要同步递归更新整棵动态面板树的矩形大小
  /// [newSize] 新的窗口尺寸
  void doLayout(Size newSize) {
    if (!_layoutDirty) return;
    // 1. 更新根节点
    final scaleX = newSize.width / _root.rect.width;
    final scaleY = newSize.height / _root.rect.height;
    _root.rect = Rect.fromLTWH(0, 0, newSize.width, newSize.height);

    // 2. 递归更新子节点
    _doLayoutChildren(_root, scaleX, scaleY);
    // 3. 更新横向分割线
    for (final line in _horizontalLines) {
      line.start *= scaleX;
      line.end *= scaleX;
      line.position *= scaleY;
    }
    // 4. 更新竖向分割线
    for (final line in _verticalLines) {
      line.start *= scaleY;
      line.end *= scaleY;
      line.position *= scaleX;
    }
    _layoutDirty = false;
  }

  void _doLayoutChildren(DynamicPanel node, double scaleX, double scaleY) {
    for (final child in node.children) {
      // 计算新的物理坐标
      child.rect = Rect.fromLTRB(
        child.rect.left * scaleX,
        child.rect.top * scaleY,
        child.rect.right * scaleX,
        child.rect.bottom * scaleY,
      );

      // 递归处理子节点
      if (child.type != DynamicPanelType.leaf) {
        _doLayoutChildren(child, scaleX, scaleY);
      }
    }
  }

  /// 查找包含某点的最内层叶子节点
  /// [node] 面板树根节点
  /// [mousePos] 光标位置
  DynamicPanel? findNearestPanelAtMousePos(DynamicPanel node, Offset mousePos) {
    if (!node.rect.contains(mousePos)) return null;

    if (node.type == DynamicPanelType.leaf) {
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
  void finalAllPanelsAtMousePos(DynamicPanel node, Rect rect, List<DynamicPanel> panels) {
    if (!node.rect.overlaps(rect)) return;

    if (node.type == DynamicPanelType.leaf) {
      panels.add(node);
    } else {
      for (final child in node.children) {
        finalAllPanelsAtMousePos(child, rect, panels);
      }
    }
  }

  // 二分查找最近的分割线
  DynamicSplitLine? _findNearestLine({
    required List<DynamicSplitLine> lines,
    required double mousePos,
    required bool isHorizontal,
    required double mouseOrthogonalPos,
    required double threshold,
  }) {
    if (lines.isEmpty) return null;

    // 二分查找第一个 position >= mousePos 的线
    int left = 0, right = lines.length - 1;
    int index = lines.length; // 默认超出范围
    while (left <= right) {
      final mid = left + (right - left) ~/ 2;
      if (lines[mid].position >= mousePos) {
        index = mid;
        right = mid - 1;
      } else {
        left = mid + 1;
      }
    }

    // 检查候选线及其前一条线
    final candidates = <DynamicSplitLine>[];
    if (index < lines.length) candidates.add(lines[index]);
    if (index > 0) candidates.add(lines[index - 1]);

    // 检查是否在容差范围内且正交坐标在线段范围内
    for (final line in candidates) {
      if ((line.position - mousePos).abs() <= threshold) {
        if (mouseOrthogonalPos >= line.start && mouseOrthogonalPos <= line.end) {
          return line;
        }
      }
    }

    return null;
  }

  // 选中面板
  void selectPanel(DynamicPanel? panel) {
    _selectedPanel = panel;
    notifyListeners();
  }

  // 设置划分模式
  void setSplitMode(SplitMode mode) {
    _splitMode = mode;
    notifyListeners();
  }

  // 查找面板是否击中（深度优先）
  DynamicPanel? hitTestPanel(DynamicPanel current, DynamicPanel target) {
    if (current == target) return current;
    for (final child in current.children) {
      final found = hitTestPanel(child, target);
      if (found != null) return found;
    }
    return null;
  }

  void _updateState(DynamicPanel? state) {
    if (state != null) {
      _root = state;
      notifyListeners();
    }
  }

  // panel 绑定 Widget
  void bindWidget(DynamicPanel current, Widget widget) {
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

  DynamicPanelType? getParentPanelType(SplitMode mode) {
    if (mode == SplitMode.horizontal) {
      return DynamicPanelType.column;
    } else if (mode == SplitMode.vertical) {
      return DynamicPanelType.row;
    } else if (mode == SplitMode.cols_3) {
      return DynamicPanelType.row;
    } else if (mode == SplitMode.rows_3) {
      return DynamicPanelType.column;
    } else if (mode == SplitMode.grid_2_2) {
      return DynamicPanelType.row;
    } else if (mode == SplitMode.grid_4_4) {
      return DynamicPanelType.row;
    }
    return null;
  }

  // 添加分割线（修改后的版本）
  void addSplitLines(Rect rect, SplitMode mode) {
    switch (mode) {
      case SplitMode.horizontal:
        // 水平中心划分 - 添加一条水平分割线
        _horizontalLines.add(
          DynamicSplitLine(
            isHorizontal: true,
            position: rect.top + rect.height / 2,
            start: rect.left,
            end: rect.right,
          ),
        );
        break;

      case SplitMode.vertical:
        // 垂直中心划分 - 添加一条垂直分割线
        _verticalLines.add(
          DynamicSplitLine(
            isHorizontal: false,
            position: rect.left + rect.width / 2,
            start: rect.top,
            end: rect.bottom,
          ),
        );
        break;

      case SplitMode.cols_3:
        // 水平三等分 - 添加两条垂直分割线
        verticalLines.addAll([
          DynamicSplitLine(
            isHorizontal: false,
            position: rect.left + rect.width / 3,
            start: rect.top,
            end: rect.bottom,
          ),
          DynamicSplitLine(
            isHorizontal: false,
            position: rect.left + rect.width * 2 / 3,
            start: rect.top,
            end: rect.bottom,
          ),
        ]);
        break;

      case SplitMode.rows_3:
        // 垂直三等分 - 添加两条水平分割线
        _horizontalLines.addAll([
          DynamicSplitLine(
            isHorizontal: true,
            position: rect.top + rect.height / 3,
            start: rect.left,
            end: rect.right,
          ),
          DynamicSplitLine(
            isHorizontal: true,
            position: rect.top + rect.height * 2 / 3,
            start: rect.left,
            end: rect.right,
          ),
        ]);
        break;

      case SplitMode.grid_2_2:
        // 修改为：一条水平线 + 两条居中垂直线
        _horizontalLines.add(
          DynamicSplitLine(
            isHorizontal: true,
            position: rect.top + rect.height / 2,
            start: rect.left,
            end: rect.right,
          ),
        );
        _verticalLines.addAll([
          DynamicSplitLine(
            isHorizontal: false,
            position: rect.left + rect.width / 2,
            start: rect.top,
            end: rect.top + rect.height / 2,
          ),
          DynamicSplitLine(
            isHorizontal: false,
            position: rect.left + rect.width * 2 / 2,
            start: rect.top + rect.height / 2,
            end: rect.bottom,
          ),
        ]);
        break;

      case SplitMode.grid_4_4:
        // 修改为：三条水平线 + 上下三等分垂直线（共9条）
        // 水平分割线（3条）
        for (int i = 1; i <= 3; i++) {
          _horizontalLines.add(
            DynamicSplitLine(
              isHorizontal: true,
              position: rect.top + rect.height * i / 3,
              start: rect.left,
              end: rect.right,
            ),
          );
        }
        // 垂直分割线 (9条)
        for (int i = 1; i <= 3; i++) {
          for (int j = 0; j < 3; j++) {
            _verticalLines.add(
              DynamicSplitLine(
                isHorizontal: false,
                position: rect.left + rect.width * i / 3,
                start: rect.top + j * rect.height / 3,
                end: rect.top + (j + 1) * rect.height / 3,
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
    DynamicPanel? panel = _selectedPanel;
    if (panel == null || panel.type != DynamicPanelType.leaf) {
      return;
    }
    // 只能对叶子节点进行分割
    List<Rect> splitRects = getSplitRects(panel.rect, mode);
    DynamicPanelType? parentPanelType = getParentPanelType(mode);
    if (parentPanelType == null) return;
    debugPrint("开始分割面板");
    panel.type = parentPanelType;
    panel.children = [];
    // 添加所有子面板
    addSplitSubPanels(panel, mode, splitRects);
    // 添加分割线
    addSplitLines(panel.rect, mode);
    _sortSplitLines(_horizontalLines);
    _sortSplitLines(_verticalLines);
  }

  void addSplitSubPanels(DynamicPanel parent, SplitMode mode, List<Rect> rects) {
    switch (mode) {
      case SplitMode.horizontal:
      case SplitMode.vertical:
      case SplitMode.rows_3:
      case SplitMode.cols_3:
        _addSimpleSplitPanels(parent, _getSplitCount(mode), rects);
        break;
      case SplitMode.grid_2_2:
        _addGrid2x2Panels(parent, rects);
        break;
      case SplitMode.grid_4_4:
        _addGrid4x4Panels(parent, rects);
        break;
      default:
        throw ArgumentError('Unsupported split mode: $mode');
    }
  }

  void _addSimpleSplitPanels(DynamicPanel parent, int splitCount, List<Rect> rects) {
    final childPercent = parent.percent / splitCount;
    parent.children.addAll(
      List.generate(
        splitCount,
        (index) => DynamicPanel(
          type: DynamicPanelType.leaf,
          rect: rects[index],
          percent: childPercent,
          widget: index == 0 ? parent.widget : null,
          groupId: parent.groupId,
        ),
      ),
    );
  }

  void _addGrid2x2Panels(DynamicPanel parent, List<Rect> rects) {
    // 创建两行
    final rowPercent = parent.percent / 2;
    final rowHeight = parent.rect.height / 2;

    parent.children.addAll([
      _createRowPanel(
        parent: parent,
        top: parent.rect.top,
        height: rowHeight,
        percent: rowPercent,
        childrenRects: [rects[0], rects[1]],
        hasWidget: true,
      ),
      _createRowPanel(
        parent: parent,
        top: parent.rect.top + rowHeight,
        height: rowHeight,
        percent: rowPercent,
        childrenRects: [rects[2], rects[3]],
        hasWidget: false,
      ),
    ]);
  }

  DynamicPanel _createRowPanel({
    required DynamicPanel parent,
    required double top,
    required double height,
    required double percent,
    required List<Rect> childrenRects,
    required bool hasWidget,
  }) {
    return DynamicPanel(
      type: DynamicPanelType.row,
      rect: Rect.fromLTWH(parent.rect.left, top, parent.rect.width, height),
      percent: percent,
      widget: null,
      groupId: parent.groupId,
      children:
          childrenRects
              .map(
                (rect) => DynamicPanel(
                  type: DynamicPanelType.leaf,
                  rect: rect,
                  percent: percent / childrenRects.length,
                  widget: hasWidget && rect == childrenRects.first ? parent.widget : null,
                  groupId: parent.groupId,
                ),
              )
              .toList(),
    );
  }

  void _addGrid4x4Panels(DynamicPanel parent, List<Rect> rects) {
    // 创建三行
    final rowPercent = parent.percent / 4;
    final rowHeight = parent.rect.height / 4;

    parent.children.addAll([
      _createRowPanel(
        parent: parent,
        top: parent.rect.top,
        height: rowHeight,
        percent: rowPercent,
        childrenRects: [rects[0], rects[1], rects[2], rects[3]],
        hasWidget: true,
      ),
      _createRowPanel(
        parent: parent,
        top: parent.rect.top + rowHeight,
        height: rowHeight,
        percent: rowPercent,
        childrenRects: [rects[4], rects[5], rects[6], rects[7]],
        hasWidget: false,
      ),
      _createRowPanel(
        parent: parent,
        top: parent.rect.top + rowHeight,
        height: rowHeight,
        percent: rowPercent,
        childrenRects: [rects[8], rects[9], rects[10], rects[11]],
        hasWidget: false,
      ),
      _createRowPanel(
        parent: parent,
        top: parent.rect.top + rowHeight,
        height: rowHeight,
        percent: rowPercent,
        childrenRects: [rects[12], rects[13], rects[14], rects[15]],
        hasWidget: false,
      ),
    ]);
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
}
