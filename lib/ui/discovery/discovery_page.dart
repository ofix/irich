import 'package:flutter/material.dart';
import 'package:irich/components/desktop_layout.dart';
import 'package:irich/ui/discovery/discovery_view.dart';

class DiscoveryPage extends StatelessWidget {
  const DiscoveryPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return DesktopLayout(
      child: Container(padding: const EdgeInsets.all(24), child: DiscoveryView(title: "选股页面")),
    );
  }
}
