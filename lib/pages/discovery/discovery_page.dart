import 'package:flutter/material.dart';
import 'package:irich/components/desktop_layout.dart';
import 'package:irich/pages/discovery/discovery_view.dart';

class DiscoveryPage extends StatelessWidget {
  const DiscoveryPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return DesktopLayout(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor,
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DiscoveryView(title: "选股页面"),
      ),
    );
  }
}
