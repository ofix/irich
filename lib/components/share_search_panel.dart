// /////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/share_search_panel.dart
// Purpose:     irich global share search panel
// Author:      songhuabiao
// Created:     2025-05-28 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// /////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/router/router_provider.dart';
import 'package:irich/store/state_quote.dart';
import 'package:irich/store/state_share_search.dart';

class OverlayManager {
  static final _overlayKey = GlobalKey<OverlayState>();
  static bool _initialized = false;

  static void ensureInitialized() {
    if (!_initialized) {
      _initialized = true;
      // 其他初始化逻辑
    }
  }

  static GlobalKey<OverlayState> get overlayKey => _overlayKey;

  static OverlayState? get overlayState {
    assert(_initialized, 'Must call ensureInitialized() first');
    return _overlayKey.currentState;
  }
}

class ShareSearchPanel {
  static OverlayEntry? _entry;
  static bool visible = false;

  static void show(String? keyword) {
    if (visible) return;

    final overlay = OverlayManager.overlayState;
    if (overlay == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => show(keyword));
      return;
    }

    _entry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                child: _ShareSearchPanelContent(initialKeyword: keyword, onDismiss: hide),
              ),
            ),
          ),
    );

    overlay.insert(_entry!);
    visible = true;
  }

  static void hide() {
    if (!visible || _entry == null) return;
    _entry?.remove();
    _entry = null;
    visible = false;
  }
}

class _ShareSearchPanelContent extends ConsumerWidget {
  final VoidCallback onDismiss;
  final String? initialKeyword;
  const _ShareSearchPanelContent({required this.onDismiss, this.initialKeyword});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        elevation: 8,
        child: Container(
          width: 320,
          constraints: const BoxConstraints(maxHeight: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [_buildSearchPanelBody(context, ref, onShareSelect)],
          ),
        ),
      ),
    );
  }

  void onShareSelect(Share share, BuildContext context, WidgetRef ref) {
    ShareSearchPanel.hide();
    final router = ref.watch(routerProvider);
    ref.read(currentShareCodeProvider.notifier).select(share.code);
    final url = router.routerDelegate.currentConfiguration.uri.path;
    // 如果当前不是股票详情页面，则跳转，否则会出现重复刷新的问题
    if (!url.startsWith('/share')) {
      router.push('/share');
    }
  }

  Widget _buildSearchPanelBody(
    BuildContext context,
    WidgetRef ref,
    void Function(Share, BuildContext, WidgetRef ref) onShareSelect,
  ) {
    final shares = ref.watch(globalSearchSharesProvider);
    final selectedIndex = ref.watch(globalSelectedShareIndexProvider);

    return Expanded(
      child: SizedBox(
        width: double.infinity,
        child: ListView.builder(
          controller: ref.watch(globalScrollContrllerProvider),
          itemCount: shares.length,
          itemBuilder: (context, index) {
            final share = shares[index];
            return GestureDetector(
              onTap: () => onShareSelect(share, context, ref),
              child: Container(
                color: selectedIndex == index ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                child: StockItem(share: share),
              ),
            );
          },
        ),
      ),
    );
  }
}

class StockItem extends StatelessWidget {
  final Share share;
  const StockItem({super.key, required this.share});

  @override
  Widget build(BuildContext context) {
    Color marketColor = getMarketColor(share.market);
    return InkWell(
      splashColor: Colors.blue.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                share.code,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Expanded(
              child: Text(
                share.name,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: marketColor),
              child: Text(
                share.market.name,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color getMarketColor(Market market) {
    switch (market) {
      case Market.shenZhen:
        return const Color.fromARGB(255, 4, 141, 210);
      case Market.chuangYeBan:
        return const Color.fromARGB(255, 205, 8, 182);
      case Market.shangHai:
        return const Color.fromARGB(255, 231, 119, 27);
      default:
        return const Color.fromARGB(255, 183, 29, 57);
    }
  }
}
