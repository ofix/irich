import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoritePanel extends ConsumerWidget {
  const FavoritePanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(padding: const EdgeInsets.all(24), child: Center(child: Text("个股详情页面")));
  }
}
