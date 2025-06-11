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
import 'package:irich/store/state_quote.dart';

// 自选股组件
class MarektShareTab extends ConsumerStatefulWidget {
  const MarektShareTab({super.key});
  @override
  ConsumerState<MarektShareTab> createState() => _MarketShareTabState();
}

class _MarketShareTabState extends ConsumerState<MarektShareTab>
    with AutomaticKeepAliveClientMixin, RouteAware {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint("初始化行情股票");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToCurrentIndex(); // 初始化时滚动
    });
  }

  @override
  void didPopNext() {
    scrollToCurrentIndex(); // 返回时恢复
    super.didPopNext();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void scrollToCurrentIndex() {
    final index = ref.read(currentShareIndexProvider);
    final controller = ref.read(marketScrollControllerProvider);
    if (controller.hasClients) {
      controller.jumpTo(index * 56.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final shareList = ref.watch(shareListProvider);
    final currentShareIndex = ref.watch(currentShareIndexProvider);
    final notifier = ref.read(currentShareIndexProvider.notifier);
    final marketScrollController = ref.watch(marketScrollControllerProvider);
    // 重复执行会绑定重复view
    int? _lastScrolledIndex; // 类成员变量

    void _scrollToIndex(int index) {
      if (_lastScrolledIndex == index || !marketScrollController.hasClients) return;
      _lastScrolledIndex = index;
      final targetOffset = index * 56.0; // 与 itemExtent 一致
      if ((marketScrollController.offset - targetOffset).abs() > 1) {
        marketScrollController.animateTo(
          index * 48.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }

    // 监听选中索引变化，自动滚动到对应位置
    ref.listen(currentShareIndexProvider, (_, newIndex) {
      _scrollToIndex(newIndex);
    });

    return ListView.builder(
      controller: marketScrollController,
      itemCount: shareList.length,
      itemExtent: 56, // 固定高度提升性能
      itemBuilder: (context, index) {
        final share = shareList[index];
        return SizedBox(
          height: 56,
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              tileColor: currentShareIndex == index ? Colors.blue : Color.fromARGB(255, 24, 24, 24),
              selectedTileColor: const Color.fromARGB(255, 26, 26, 26),
              selectedColor: Color.fromARGB(255, 240, 190, 131),
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
              selected: index == currentShareIndex,
              onTap: () {
                ref.read(shareTabIndexProvider.notifier).state = 0; // 自选股是第二个 Tab
                notifier.setSelected(index);
                ref.read(lastScrollOffsetProvider.notifier).state = marketScrollController.offset;
                debugPrint("设置当前选中的股票索引为: $index");
                ref.read(currentShareCodeProvider.notifier).select(share.code);
              },
            ),
          ),
        );
      },
    );
  }

  // 滚动到指定索引
}
