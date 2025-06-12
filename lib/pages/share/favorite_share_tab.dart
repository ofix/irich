// /////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/pages/share/favorite_share_tab.dart
// Purpose:     irich favorite shares tab view
// Author:      songhuabiao
// Created:     2025-06-03 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// /////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/state_quote.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoriteShareTab extends ConsumerStatefulWidget {
  const FavoriteShareTab({super.key});

  @override
  ConsumerState<FavoriteShareTab> createState() => _FavoriteShareTabState();
}

class _FavoriteShareTabState extends ConsumerState<FavoriteShareTab>
    with AutomaticKeepAliveClientMixin {
  List<Share> watchShares = [];

  late ScrollController scrollController;
  int currentShareIndex = 0;
  int lastShareIndex = 0;
  Map<String, int> posMap = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    watchShares = ref.read(watchShareListProvider);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void buildFavoriteShareIndex() {
    watchShares = ref.read(watchShareListProvider);
    for (int i = 0; i < watchShares.length; i++) {
      posMap[watchShares[i].code] = i;
    }
  }

  int getScrollIndex(String shareCode) {
    return posMap[shareCode] ?? 0;
  }

  void scrollToCurrentIndex() {
    if (lastShareIndex == currentShareIndex || !scrollController.hasClients) return;
    lastShareIndex = currentShareIndex;
    final targetOffset = currentShareIndex * 56.0; // 与 itemExtent 一致
    if ((scrollController.offset - targetOffset).abs() > 1) {
      scrollController.animateTo(
        currentShareIndex * 56.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    watchShares = ref.watch(watchShareListProvider);
    // 监听用户输入股票变化，自动滚动到对应位置，用户单击列表本身不触发滚动
    ref.listen(currentShareCodeProvider, (_, newShareCode) {
      final posIndex = getScrollIndex(newShareCode);
      if (posIndex != 0) {
        scrollToCurrentIndex();
      }
    });

    Widget buildShareList(BuildContext context, List<Share> shares) {
      return ListView.builder(
        controller: scrollController,
        itemCount: shares.length,
        itemExtent: 56,
        itemBuilder: (context, index) {
          final share = shares[index];
          return SizedBox(
            height: 56,
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                tileColor:
                    currentShareIndex == index ? Colors.blue : Color.fromARGB(255, 24, 24, 24),
                selectedTileColor: const Color.fromARGB(255, 26, 26, 26),
                selectedColor: Color.fromARGB(255, 240, 190, 131),
                selected: index == currentShareIndex,
                dense: true, // 紧凑模式
                visualDensity: VisualDensity.compact, // 减少默认高
                title: Text(share.name),
                subtitle: Text(share.code),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      share.priceNow.toStringAsFixed(2),
                      style: TextStyle(color: share.changeRate >= 0 ? Colors.red : Colors.green),
                    ),
                    Text(
                      '${share.changeRate >= 0 ? '' : '-'}${(share.changeRate * 100).toStringAsFixed(2)}%',
                      style: TextStyle(color: share.changeRate >= 0 ? Colors.red : Colors.green),
                    ),
                  ],
                ),
                onTap: () => _onShareSelected(context, share.code, index),
              ),
            ),
          );
        },
      );
    }

    if (watchShares.isEmpty) {
      return _buildEmptyView(context);
    }
    return buildShareList(context, watchShares);
  }

  void _onShareSelected(BuildContext context, String shareCode, int index) {
    lastShareIndex = currentShareIndex = index;
    ref.read(currentShareCodeProvider.notifier).select(shareCode);
    setState(() {});
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 48, color: const Color.fromARGB(255, 65, 64, 64)),
          const SizedBox(height: 16),
          Text('暂无自选股', style: TextStyle(color: Color.fromARGB(255, 24, 24, 24), fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => GoRouter.of(context).push('/share/search'),
            child: const Text('添加自选股'),
          ),
        ],
      ),
    );
  }
}
