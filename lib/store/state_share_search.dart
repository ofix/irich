// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/state_share_search.dart
// Purpose:     global shere search state
// Author:      songhuabiao
// Created:     2025-06-02 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/share_search_panel.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/store_quote.dart';

final globalSearchKeywordProvider = StateProvider<String>((ref) => "");
final globalSearchSharesProvider = StateProvider<List<Share>>((ref) => []);
final globalSelectedShareIndexProvider = StateProvider<int>((ref) => -1);
final globalInputControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});
final globalSearchFocusNodeProvider = Provider<FocusNode>((ref) {
  final node = FocusNode();
  ref.onDispose(() => node.dispose());
  return node;
});
final globalScrollContrllerProvider = Provider<ScrollController>((ref) {
  final controller = ScrollController();
  ref.onDispose(() => controller.dispose());
  return controller;
});
// 键盘事件监听 Provider（核心实现）
final globalKeyboardListenerProvider = Provider.autoDispose<bool>((ref) {
  final focusNode = ref.watch(globalSearchFocusNodeProvider);
  final controller = ref.read(globalInputControllerProvider);

  bool handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // 按下任意键时自动获取焦点（排除功能键）
      if (!focusNode.hasFocus &&
          event.character != null &&
          event.logicalKey != LogicalKeyboardKey.control &&
          event.logicalKey != LogicalKeyboardKey.alt) {
        focusNode.requestFocus();
      }

      if (event.logicalKey == LogicalKeyboardKey.escape) {
        // 清空输入框内容
        controller.text = "";
        controller.selection = TextSelection.collapsed(offset: controller.text.length);
        ShareSearchPanel.hide();
        return true;
      }

      // 处理普通字符输入
      if (event.character != null &&
          event.logicalKey != LogicalKeyboardKey.control &&
          event.logicalKey != LogicalKeyboardKey.alt) {
        if (!ShareSearchPanel.visible) {
          // 初始化输入框和搜索列表
          controller.text = event.character!;
          controller.selection = TextSelection.collapsed(offset: controller.text.length);
          final result = StoreQuote.searchShares(event.character!);
          ref.read(globalSearchSharesProvider.notifier).state = result;
        }
        ShareSearchPanel.show(event.character);
        return false;
      }
    }
    return false;
  }

  // 注册监听器
  HardwareKeyboard.instance.addHandler(handleKeyEvent);

  // 确保单例存在
  ref.onDispose(() {
    debugPrint('Disposing keyboard listener');
    HardwareKeyboard.instance.removeHandler(handleKeyEvent);
  });
  return true;
});
