import 'package:flutter/material.dart';
import 'package:irich/components/desktop_layout.dart';
import 'package:irich/pages/market/market_view.dart';

class MarketPage extends StatelessWidget {
  const MarketPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return DesktopLayout(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: MarketView(title: "行情页面"),
      ),
    );
  }
}
