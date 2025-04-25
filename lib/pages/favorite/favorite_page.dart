import 'package:flutter/material.dart';
import 'package:irich/components/desktop_layout.dart';
import 'package:irich/pages/favorite/favorite_view.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return DesktopLayout(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: FavoriteView(title: "自选页面"),
      ),
    );
  }
}
