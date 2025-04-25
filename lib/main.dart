import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/router/router_provider.dart';
import 'package:irich/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: RichApp()));
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
      routerConfig: router,
    );
  }
}
