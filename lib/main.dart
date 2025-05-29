// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/main.dart
// Purpose:     irich application main entry
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/share_search_panel.dart';
import 'package:irich/router/router_provider.dart';
import 'package:irich/service/sql_service.dart';
import 'package:irich/service/trading_calendar.dart';
import 'package:irich/theme/app_theme.dart';
import 'package:irich/utils/file_tool.dart';

void main() async {
  // 确保WidgetsBinding已初始化
  WidgetsFlutterBinding.ensureInitialized();
  // 拷贝文件到可执行文件目录
  await FileTool.installDir("lib/runtime");
  // 加载交易日期数据文件并初始化
  await TradingCalendar().initialize();
  // 初始化数据库SQLite
  await initDatabase();
  runApp(ProviderScope(child: RichApp()));
  // 注册全局键盘监听回调
  registerGlobalKeyEventListener();
}

// 全局键盘事件监听
void registerGlobalKeyEventListener() {
  HardwareKeyboard.instance.addHandler((event) {
    if (event is KeyDownEvent) {
      // 仅处理按下事件
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        ShareSearchPanel.hide();
        return true; // 拦截 Escape
      }
      // 仅当有字符输入时才显示面板（排除功能键）
      if (event.character != null && event.character!.isNotEmpty) {
        ShareSearchPanel.show(event.character!);
      }
    }
    return false; // 允许其他事件传播
  });
}

// 初始化数据库
Future<void> initDatabase() async {
  try {
    await SqlService.instance.database;
    debugPrint('Database initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize database: $e');
  }
}

class RichApp extends ConsumerWidget {
  RichApp({super.key});
  final _appOverlayKey = GlobalKey<OverlayState>();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    OverlayManager.init(_appOverlayKey); // 初始化
    return MaterialApp.router(
      title: '东方价值',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) {
        return Overlay(key: _appOverlayKey, initialEntries: [OverlayEntry(builder: (_) => child!)]);
      },
    );
  }
}
