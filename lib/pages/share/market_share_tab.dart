// /////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/pages/share/market_share_tab.dart
// Purpose:     display market shares and favorite shares in tab view
// Author:      songhuabiao
// Created:     2025-06-03 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// /////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irich/store/state_quote.dart';

// 自选股组件
class MarektShareTab extends ConsumerWidget {
  const MarektShareTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shareList = ref.watch(shareListProvider);
    final currentShareIndex = ref.watch(currentShareIndexProvider);
    final notifier = ref.watch(shareListProvider.notifier);
    final ScrollController scrollController = ScrollController();

    // 监听选中索引变化，自动滚动到对应位置
    ref.listen(currentShareIndexProvider, (_, newIndex) {
      _scrollToIndex(newIndex, scrollController);
    });

    return ListView.builder(
      controller: scrollController,
      itemCount: shareList.length,
      itemExtent: 56, // 固定高度提升性能
      itemBuilder: (context, index) {
        final share = shareList[index];
        return ListTile(
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
          selected: index == currentShareIndex,
          onTap: () {
            notifier.setSelectedIndex(index);
            GoRouter.of(context).push('/share/${share.code}');
          },
        );
      },
    );
  }

  // 滚动到指定索引
  void _scrollToIndex(int index, ScrollController controller) {
    final double itemHeight = 50.0; // 假设列表项高度固定
    final double offset = index * itemHeight;
    controller.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}
