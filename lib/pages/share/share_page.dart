import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 个股详情页面
class SharePage extends ConsumerWidget {
  const SharePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(padding: const EdgeInsets.all(24), child: Center(child: Text(title)));
  }
}
