// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/share_search_panel.dart
// Purpose:     irich global share search panel
// Author:      songhuabiao
// Created:     2025-05-28 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
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
            right: 2,
            bottom: 2,
            child: Material(
              child: _ShortcutPanelContent(keyword: keyword, onDismiss: ShareSearchPanel.hide),
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
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 320, // 固定宽度防止无限扩展
        constraints: BoxConstraints(maxHeight: 500), // 限制最大高度
        child: Column(
          mainAxisSize: MainAxisSize.min, // 防止垂直无限扩展
          children: [
            // 标题栏
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Text('键盘精灵', style: TextStyle(color: Colors.white)),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),
            ),

            // 搜索框
            Padding(
              padding: EdgeInsets.all(8),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true, //
                decoration: InputDecoration(
                  hintText: '请输入股票名称或代码',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: (text) {
                  setState(() => _keyword = text.trim());
                  _searchShares();
                },
              ),
            ),

            // 分隔线
            Divider(height: 1),

            // 结果列表
            Expanded(
              child: SizedBox(
                width: double.infinity, // 关键修复：确保宽度填满
                child: ListView.builder(
                  itemCount: _shares.length,
                  itemBuilder: (context, index) {
                    final share = _shares[index];
                    return StockItem(
                      code: share.code,
                      name: share.name,
                      market: share.market.name,
                      onTap: () => _handleStockSelect(share),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 用户需要搜索的股票
  void _handleStockSelect(Share share) {
    // debugPrint("用户选中了股票: ${share.code}, ${share.name}");
  }
}

class StockItem extends StatelessWidget {
  final String code; // 股票代码
  final String name; // 股票名称
  final String market; // 所属市场（如: 沪市/深市/港股等）
  final VoidCallback onTap;

  const StockItem({
    required this.code,
    required this.name,
    required this.market,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.blue.withOpacity(0.1), // 浅色水波纹
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 股票代码（加粗显示）
            SizedBox(
              width: 80, // 固定宽度对齐
              child: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),

            // 股票名称（自动换行）
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 市场标签（灰色小字）
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(market, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
