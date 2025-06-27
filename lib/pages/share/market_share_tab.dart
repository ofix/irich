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
import 'package:irich/global/stock.dart';
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
  late ScrollController scrollController;

  int lastShareIndex = 0; // 上一次股票的序号
  int currentShareIndex = 0; // 这一次股票的序号
  late List<Share> shareList;
  Map<String, int> posHash = {};

  @override
  void initState() {
    super.initState();
    // 初始化滚动控制器
    scrollController = ScrollController();
    // 读取股票列表并映射股票在列表中的位置序号
    shareList = ref.read(shareListProvider);
    for (int i = 0; i < shareList.length; i++) {
      posHash[shareList[i].code] = i;
    }
    // 读取当前设置的股票代码
    String shareCode = ref.read(currentShareCodeProvider);
    // 获取当前股票位置序号
    currentShareIndex = getScrollIndex(shareCode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToCurrentIndex(); // 初始化时滚动
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  int getScrollIndex(shareCode) {
    return posHash[shareCode]!;
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
    // 监听用户输入股票变化，自动滚动到对应位置，用户单击列表本身不触发滚动
    ref.listen(currentShareCodeProvider, (_, newShareCode) {
      currentShareIndex = getScrollIndex(newShareCode);
      scrollToCurrentIndex();
    });
    return ListView.builder(
      controller: scrollController,
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
                    '${(share.changeRate * 100).toStringAsFixed(2)}%',
                    style: TextStyle(color: share.changeRate >= 0 ? Colors.red : Colors.green),
                  ),
                ],
              ),
              selected: index == currentShareIndex,
              onTap: () {
                lastShareIndex = index;
                currentShareIndex = index;
                setState(() {});
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
