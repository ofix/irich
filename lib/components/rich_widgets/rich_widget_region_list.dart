// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/rich_widgets/rich_widget_region_list.dart
// Purpose:     region list rich widget
// Author:      songhuabiao
// Created:     2025-07-03 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/rich_widgets/rich_widget.dart';
import 'package:irich/store/rich_widgets/rich_widget_provider.dart';
import 'package:irich/store/rich_widgets/rich_widget_provider_industry.dart';
import 'package:irich/store/rich_widgets/rich_widget_provider_region.dart';

// 股票概念列表
class RichWidgetRegionList extends RichWidget {
  const RichWidgetRegionList({super.key, required super.panelId, super.groupId = 0});
  @override
  ConsumerState<RichWidgetRegionList> createState() => _RichWidgetRegionListState();
}

class _RichWidgetRegionListState extends ConsumerState<RichWidgetRegionList>
    with AutomaticKeepAliveClientMixin, RouteAware {
  @override
  bool get wantKeepAlive => true;
  late ScrollController scrollController;
  int lastIndex = 0; // 上一次股票的序号
  int currentIndex = 0; // 这一次股票的序号
  late List<String> regionList;
  Map<String, int> posHash = {};

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    regionList = ref.read(
      richWidgetRegionProviders(RichWidgetParams(panelId: widget.panelId, groupId: widget.groupId)),
    );
    for (int i = 0; i < regionList.length; i++) {
      posHash[regionList[i]] = i;
    }
    // 读取当前设置的股票代码
    String regionName = regionList.first;
    // 获取当前股票位置序号
    currentIndex = getScrollIndex(regionName);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToCurrentIndex(); // 初始化时滚动
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // 监听指定名称的面板的指定数据
    ref.watch(
      richWidgetIndustryProviders(
        RichWidgetParams(panelId: widget.panelId, groupId: widget.groupId),
      ),
    );
    return ListView.builder(
      controller: scrollController,
      itemCount: regionList.length,
      itemExtent: 56, // 固定高度提升性能
      itemBuilder: (context, index) {
        final region = regionList[index];
        return SizedBox(
          height: 56,
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              tileColor: currentIndex == index ? Colors.blue : Color.fromARGB(255, 24, 24, 24),
              selectedTileColor: const Color.fromARGB(255, 26, 26, 26),
              selectedColor: Color.fromARGB(255, 240, 190, 131),
              dense: true, // 紧凑模式
              visualDensity: VisualDensity.compact, // 减少默认高
              title: Text(region),
              subtitle: Text(region),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [Text("", style: TextStyle(color: Colors.red))],
              ),
              selected: index == currentIndex,
              onTap: () {
                lastIndex = index;
                currentIndex = index;
                setState(() {});
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  int getScrollIndex(shareCode) {
    return posHash[shareCode]!;
  }

  void scrollToCurrentIndex() {
    if (lastIndex == currentIndex || !scrollController.hasClients) return;
    lastIndex = currentIndex;
    final targetOffset = currentIndex * 56.0; // 与 itemExtent 一致
    if ((scrollController.offset - targetOffset).abs() > 1) {
      scrollController.animateTo(
        currentIndex * 56.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
