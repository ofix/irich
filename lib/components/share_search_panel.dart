// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/share_search_panel.dart
// Purpose:     irich global share search panel
// Author:      songhuabiao
// Created:     2025-05-28 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/store_quote.dart';

class OverlayManager {
  static var _overlayKey = GlobalKey<OverlayState>();

  static void init(GlobalKey<OverlayState> key) {
    _overlayKey = key;
  }

  static OverlayState? get overlayState {
    try {
      return _overlayKey.currentState;
    } catch (e) {
      return null;
    }
  }
}

class ShareSearchPanel {
  static OverlayEntry? _entry;
  static bool visible = false;
  static void show(String? keyword) {
    if (visible) {
      return;
    }
    final overlay = OverlayManager.overlayState;
    if (overlay == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ShareSearchPanel.show(keyword));
      return;
    }

    _entry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                child: _ShortcutPanelContent(keyword: keyword, onDismiss: ShareSearchPanel.hide),
              ),
            ),
          ),
    );
    overlay.insert(_entry!);
    visible = true;
  }

  static void hide() {
    if (!visible || _entry == null) return; // 防止 onDismiss 重复调用 hide 导致异常
    _entry?.remove();
    _entry = null;
    visible = false;
  }
}

class _ShortcutPanelContent extends StatefulWidget {
  final VoidCallback onDismiss;
  final String? keyword;

  const _ShortcutPanelContent({required this.keyword, required this.onDismiss});

  @override
  _ShortcutPanelContentState createState() => _ShortcutPanelContentState();
}

class _ShortcutPanelContentState extends State<_ShortcutPanelContent> {
  String _keyword = '';
  List<Share> _shares = [];

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  int _selectedIndex = -1; // 当前选中行

  @override
  void initState() {
    super.initState();
    _keyword = widget.keyword ?? '';
    _searchController.text = _keyword;
    _searchShares();

    // 关键修改：确保面板完全显示后再请求焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _searchShares() async {
    if (_keyword.isEmpty) {
      setState(() => _shares = []);
      return;
    }

    final result = StoreQuote.searchShares(_keyword);
    setState(() => _shares = result);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(), // 捕获全局键盘事件
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          _handleKeyDown(event.logicalKey);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.blue.withOpacity(0.3), // 半透明蓝色边框
            width: 1.5, // 边框粗细
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Material(
          elevation: 8,
          child: Container(
            width: 280, // 固定宽度防止无限扩展
            constraints: BoxConstraints(maxHeight: 380), // 限制最大高度
            child: Column(
              mainAxisSize: MainAxisSize.min, // 防止垂直无限扩展
              children: [_buildSearchPanelHeader(), _buildSearchBox(), _buildSearchPanelBody()],
            ),
          ),
        ),
      ),
    );
  }

  // 标题栏
  Widget _buildSearchPanelHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Text('键盘精灵', style: TextStyle(color: Colors.white, fontSize: 18)),
          Spacer(),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 16),
            onPressed: widget.onDismiss,
          ),
        ],
      ),
    );
  }

  // 搜索框
  Widget _buildSearchBox() {
    // 搜索框
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 添加水平内边距
      child: SizedBox(
        height: 32,
        child: Align(
          alignment: Alignment.centerLeft, // 左对齐
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: true, //
            style: TextStyle(fontSize: 16), // 统一文字大小
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 12), // 微调图标位置
                child: Icon(Icons.search, size: 24), // 固定图标大小
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[300]!), // 更细的边框
              ),
              contentPadding: const EdgeInsets.only(bottom: 12), // 调整文字垂直位置
              isDense: true, // 关键参数：减少内部padding
            ),
            onChanged: (text) {
              setState(() => _keyword = text.trim());
              _searchShares();
            },
          ),
        ),
      ),
    );
  }

  // 结果列表
  Widget _buildSearchPanelBody() {
    return Expanded(
      child: SizedBox(
        width: double.infinity, // 关键修复：确保宽度填满
        child: ListView.builder(
          controller: _scrollController, // 确保控制器附加
          itemCount: _shares.length,
          itemBuilder: (context, index) {
            final share = _shares[index];
            return GestureDetector(
              onTap: () => _onShareSelect(share),
              child: Container(
                color: _selectedIndex == index ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                child: StockItem(share: share),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleKeyDown(LogicalKeyboardKey key) {
    if (_shares.isEmpty || !_scrollController.hasClients) return;

    setState(() {
      // 上下方向键选择
      if (key == LogicalKeyboardKey.arrowDown) {
        _selectedIndex = (_selectedIndex + 1).clamp(0, _shares.length - 1);
        _scrollToSelected();
      } else if (key == LogicalKeyboardKey.arrowUp) {
        _selectedIndex = (_selectedIndex - 1).clamp(0, _shares.length - 1);
        _scrollToSelected();
      }
      // Enter键确认选择
      else if (key == LogicalKeyboardKey.enter && _selectedIndex != -1) {
        _onShareSelect(_shares[_selectedIndex]);
      }
    });
  }

  // 自动滚动到选中行
  // 延迟确保ListView已构建
  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _selectedIndex * 28.0,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 用户需要搜索的股票
  void _onShareSelect(Share share) {
    GoRouter.of(context).push('/share/${share.code}');
    widget.onDismiss();
  }
}

class StockItem extends StatelessWidget {
  final Share share;

  const StockItem({super.key, required this.share});

  @override
  Widget build(BuildContext context) {
    Color marketColor = getMarketColor(share.market);
    return InkWell(
      splashColor: Colors.blue.withOpacity(0.1), // 浅色水波纹
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 股票代码（加粗显示）
            SizedBox(
              width: 80, // 固定宽度对齐
              child: Text(
                share.code,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),

            // 股票名称（自动换行）
            Expanded(
              child: Text(
                share.name,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 市场标签（灰色小字）
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: marketColor),
              child: Text(share.market.name, style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Color getMarketColor(Market market) {
    if (market == Market.shenZhen) {
      return Color.fromARGB(255, 4, 141, 210);
    } else if (market == Market.chuangYeBan) {
      return Color.fromARGB(255, 205, 8, 182);
    } else if (market == Market.shangHai) {
      return Color.fromARGB(255, 231, 119, 27);
    }
    return Color.fromARGB(255, 183, 29, 57);
  }
}
