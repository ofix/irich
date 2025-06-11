// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/desktop_app_bar.dart
// Purpose:     desktop app bar
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irich/components/desktop_app_buttons.dart';
import 'package:irich/components/share_search_panel.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/router/router_provider.dart';
import 'package:irich/store/state_quote.dart';
import 'package:irich/store/state_share_search.dart';
import 'package:irich/store/store_quote.dart';
import 'package:window_manager/window_manager.dart';

class DesktopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const DesktopAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  void _scrollToSelected(WidgetRef ref) {
    final scrollController = ref.read(globalScrollContrllerProvider);
    final selectedIndex = ref.read(globalSelectedShareIndexProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          selectedIndex * 28.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputController = ref.watch(globalInputControllerProvider);
    final scrollController = ref.watch(globalScrollContrllerProvider);
    final inputFocusNode = ref.watch(globalSearchFocusNodeProvider);
    final shares = ref.watch(globalSearchSharesProvider);
    final selectedIndex = ref.watch(globalSelectedShareIndexProvider);

    void handleKeyDown(LogicalKeyboardKey key, BuildContext context) {
      if (shares.isEmpty || !scrollController.hasClients) return;

      if (key == LogicalKeyboardKey.arrowDown) {
        ref.read(globalSelectedShareIndexProvider.notifier).state = (selectedIndex + 1).clamp(
          0,
          shares.length - 1,
        );
        _scrollToSelected(ref);
      } else if (key == LogicalKeyboardKey.arrowUp) {
        ref.read(globalSelectedShareIndexProvider.notifier).state = (selectedIndex - 1).clamp(
          0,
          shares.length - 1,
        );
        _scrollToSelected(ref);
      } else if (key == LogicalKeyboardKey.enter && selectedIndex != -1) {
        // 清除输入框内容
        inputController.text = "";
        inputController.selection = TextSelection.collapsed(offset: inputController.text.length);
        onShareSelect(shares[selectedIndex], context, ref);
      }
    }

    return KeyboardListener(
      focusNode: FocusNode(), // 捕获全局键盘事件
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          handleKeyDown(event.logicalKey, context);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) => windowManager.startDragging(),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 31, 31, 31),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Mac风格左侧按钮
              // if (Platform.isMacOS) const Positioned(left: 12, child: DesktopAppButtons()),

              // 品牌Logo
              if (!Platform.isMacOS) _buildLogo(),

              // 居中搜索框
              _buildSearchBox(ref, inputController, inputFocusNode),

              // Windows风格右侧按钮
              if (!Platform.isMacOS) const Positioned(right: 12, child: DesktopAppButtons()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Positioned(
      left: 12,
      top: 8,
      child: SizedBox(
        width: 280, // 设置足够宽度
        height: 48, // 设置足够高度
        child: Stack(
          clipBehavior: Clip.none, // 允许子元素溢出
          children: [
            Positioned(
              left: 12,
              child: SvgPicture.asset('images/irich.svg', width: 32, height: 32),
            ),
            Positioned(
              left: 16, // 根据SVG宽度调整
              top: -8, // 微调垂直位置
              child: Image.asset('images/skymoney.png', height: 42, fit: BoxFit.fitHeight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox(WidgetRef ref, TextEditingController controller, FocusNode focusNode) {
    return Center(
      child: SizedBox(
        width: 320,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: '搜索股票/代码...',
              hintStyle: const TextStyle(color: Color(0xFFC0C0C0)),
              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFFC0C0C0)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (text) {
              ref.read(globalSearchKeywordProvider.notifier).state = text;
              _searchShares(ref, text);
              if (text.isNotEmpty && !ShareSearchPanel.visible) {
                ShareSearchPanel.show(text);
              }
            },
            onSubmitted: (text) {
              _searchShares(ref, text);
            },
          ),
        ),
      ),
    );
  }

  void _searchShares(WidgetRef ref, String keyword) {
    if (keyword.isEmpty) {
      ref.read(globalSearchSharesProvider.notifier).state = [];
      return;
    }
    final result = StoreQuote.searchShares(keyword);
    ref.read(globalSearchSharesProvider.notifier).state = result;
  }
}
