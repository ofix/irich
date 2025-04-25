import 'package:flutter/material.dart';
import 'desktop_app_bar.dart';
import 'desktop_menu.dart';

class DesktopLayout extends StatelessWidget {
  final Widget child;
  
  const DesktopLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 顶部菜单栏 (macOS风格)
          const DesktopAppBar(),
          // 主内容区
          Expanded(
            child: Row(
              children: [
                // 左侧固定菜单
                const DesktopMenu(),
                // 内容区域
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}