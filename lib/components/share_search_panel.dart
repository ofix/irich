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
import 'package:irich/global/stock.dart';
import 'package:irich/store/store_quote.dart';

class ShareSearchPanel {
  late OverlayEntry _overlayEntry;

  ShareSearchPanel(); // 你已经实现的Trie树

  void show(BuildContext context) {
    _overlayEntry?.remove(); // 先移除已有面板
    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            right: 2,
            bottom: 2,
            child: Material(child: _ShortcutPanelContent(onDismiss: hide)),
          ),
    );
    Overlay.of(context).insert(_overlayEntry);
  }

  void hide() {
    _overlayEntry?.remove();
  }
}

class _ShortcutPanelContent extends StatefulWidget {
  final VoidCallback onDismiss;

  const _ShortcutPanelContent({required this.onDismiss});

  @override
  _ShortcutPanelContentState createState() => _ShortcutPanelContentState();
}

class _ShortcutPanelContentState extends State<_ShortcutPanelContent> {
  String _keyword = '';
  List<Share> _shares = [];

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKeyEvent,
      child: Column(
        children: [
          // 输入显示区
          Text(_keyword, style: TextStyle(fontSize: 24)),
          // 搜索结果列表
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: _shares.length,
              itemBuilder: (ctx, index) {
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
        ],
      ),
    );
  }

  // 用户需要搜索的股票
  void _handleStockSelect(Share share) {
    debugPrint("用户选中了股票: ${share.code}, ${share.name}");
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // 处理字母输入
      if (event.logicalKey.keyLabel.length == 1) {
        setState(() {
          _keyword += event.logicalKey.keyLabel.toLowerCase();
          _shares = StoreQuote.searchShares(_keyword);
        });
      }
      // 处理删除键
      else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        setState(() {
          _keyword = _keyword.substring(0, _keyword.length - 1);
          _shares = StoreQuote.searchShares(_keyword);
        });
      }
      // 处理ESC键关闭
      else if (event.logicalKey == LogicalKeyboardKey.escape) {
        widget.onDismiss();
      }
    }
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
