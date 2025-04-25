import 'package:flutter/material.dart';
import 'package:irich/components/desktop_menu.dart';
class MobileLayout extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;

  const MobileLayout({
    super.key,
    required this.body,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title != null ? Text(title!) : null,
        actions: actions,
      ),
      drawer: const DesktopMenu(),
      body: body,
    );
  }
}