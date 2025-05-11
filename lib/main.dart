// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/main.dart
// Purpose:     irich application main entry
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  runApp(const ProviderScope(child: RichApp()));
}

Future<void> initDatabase() async {
  // 初始化数据库
  try {
    await SqlService.instance.database;
    debugPrint('Database initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize database: $e');
  }
}

class RichApp extends ConsumerWidget {
  const RichApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '东方价值',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
