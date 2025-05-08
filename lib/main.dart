import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/router/router_provider.dart';
import 'package:irich/service/sql_service.dart';
import 'package:irich/theme/app_theme.dart';
import 'package:irich/utils/file_tool.dart';

void main() async {
  // 确保WidgetsBinding已初始化
  WidgetsFlutterBinding.ensureInitialized();
  await FileTool.installDir("lib/runtime");
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
