// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/rich_widgets/rich_widget_watch_list.dart
// Purpose:     watch list rich widget
// Author:      songhuabiao
// Created:     2025-07-02 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/rich_widgets/rich_widget.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/rich_widgets/rich_widget_provider_watch_list.dart';

// 市场行情列表控件
class RichWidgetWatchList extends RichWidget {
  const RichWidgetWatchList({super.key, required super.panelId, super.groupId = 0});
  @override
  ConsumerState<RichWidgetWatchList> createState() => _RichWidgetWatchListState();
}

class _RichWidgetWatchListState extends ConsumerState<RichWidgetWatchList>
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
    scrollController = ScrollController();
    shareList = ref.read(
      richWidgetWatchListProviders(
        RichWidgetWatchListParams(panelId: widget.panelId, groupId: widget.groupId),
      ),
    );
    for (int i = 0; i < shareList.length; i++) {
      posHash[shareList[i].code] = i;
    }
    // 读取当前设置的股票代码
    String shareCode = shareList.first.code;
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // 监听指定名称的面板的指定数据
    ref.watch(
      richWidgetWatchListProviders(
        RichWidgetWatchListParams(panelId: widget.panelId, groupId: widget.groupId),
      ),
    );
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
              },
            ),
          ),
        );
      },
    );
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
}
