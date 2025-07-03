// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/rich_widgets/rich_widget_concept_list.dart
// Purpose:     concept list rich widget
// Author:      songhuabiao
// Created:     2025-07-02 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/rich_widgets/rich_widget.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/rich_widgets/rich_widget_provider.dart';
import 'package:irich/store/rich_widgets/rich_widget_provider_concept.dart';

// 股票概念列表
class RichWidgetConceptList extends RichWidget {
  const RichWidgetConceptList({super.key, required super.panelId, super.groupId = 0});
  @override
  ConsumerState<RichWidgetConceptList> createState() => _RichWidgetConceptListState();
}

class _RichWidgetConceptListState extends ConsumerState<RichWidgetConceptList>
    with AutomaticKeepAliveClientMixin, RouteAware {
  @override
  bool get wantKeepAlive => true;
  late ScrollController scrollController;
  int lastIndex = 0; // 上一次股票的序号
  int currentIndex = 0; // 这一次股票的序号
  late List<ShareConcept> conceptList;
  Map<String, int> posHash = {};

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    conceptList = ref.read(
      richWidgetConceptProviders(
        RichWidgetParams(panelId: widget.panelId, groupId: widget.groupId),
      ),
    );
    for (int i = 0; i < conceptList.length; i++) {
      posHash[conceptList[i].name] = i;
    }
    // 读取当前设置的股票代码
    String industryName = conceptList.first.name;
    // 获取当前股票位置序号
    currentIndex = getScrollIndex(industryName);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToCurrentIndex(); // 初始化时滚动
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // 监听指定名称的面板的指定数据
    ref.watch(
      richWidgetConceptProviders(
        RichWidgetParams(panelId: widget.panelId, groupId: widget.groupId),
      ),
    );
    return ListView.builder(
      controller: scrollController,
      itemCount: conceptList.length,
      itemExtent: 56, // 固定高度提升性能
      itemBuilder: (context, index) {
        final industry = conceptList[index];
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
              title: Text(industry.name),
              subtitle: Text(industry.name),
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
