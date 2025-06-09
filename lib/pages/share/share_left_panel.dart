// /////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/pages/share/share_left_panel.dart
// Purpose:     irich share left panel
// Author:      songhuabiao
// Created:     2025-06-03 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// /////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/pages/share/favorite_share_tab.dart';
import 'package:irich/pages/share/market_share_tab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/store/state_quote.dart';

// 1. 定义全局 Provider 管理 Tab 状态

class ShareLeftPanel extends ConsumerStatefulWidget {
  const ShareLeftPanel({super.key});

  @override
  ConsumerState<ShareLeftPanel> createState() => _ShareLeftPanelState();
}

class _ShareLeftPanelState extends ConsumerState<ShareLeftPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 2. 初始化时从 Provider 读取保存的索引
    final initialIndex = ref.read(shareTabIndexProvider);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex, // 绑定持久化的索引
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 3. 同步 Provider 和 TabController 的状态
    _tabController.addListener(_syncTabState);
  }

  void _syncTabState() {
    if (_tabController.indexIsChanging) {
      ref.read(shareTabIndexProvider.notifier).state = _tabController.index;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_syncTabState);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 4. 监听 Provider 变化（用于外部强制切换 Tab）
    ref.listen<int>(shareTabIndexProvider, (_, newIndex) {
      if (newIndex != _tabController.index) {
        _tabController.animateTo(newIndex);
      }
    });

    return Container(
      width: 300,
      color: const Color.fromARGB(255, 24, 24, 24),
      child: Column(
        children: [
          Row(
            children: [
              _buildTab(
                icon: Icons.trending_up,
                label: '市场行情',
                isSelected: _tabController.index == 0,
                onTap: () => onToggleTab(0),
              ),
              _buildTab(
                icon: Icons.star,
                label: '自选股',
                isSelected: _tabController.index == 1,
                onTap: () => onToggleTab(1),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [MarektShareTab(), FavoriteShareTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click, // 设置光标为可点击样式
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(color: const Color.fromARGB(255, 28, 29, 33)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color:
                      isSelected
                          ? Color.fromARGB(255, 7, 232, 244)
                          : Color.fromARGB(255, 255, 255, 255),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color:
                        isSelected
                            ? Color.fromARGB(255, 7, 232, 244)
                            : Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onToggleTab(int tabIndex) {
    // 5. 通过修改 Provider 来切换 Tab（自动触发监听器）
    ref.read(shareTabIndexProvider.notifier).state = tabIndex;
  }
}
