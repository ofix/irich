import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/kline_ctrl/kline_ctrl.dart';
import 'package:irich/store/provider_kline_grid.dart';

class MultiKlineView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(multiKlineProvider);
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
      itemCount: state.shares.length,
      itemBuilder: (_, index) {
        final shareCode = state.shares.keys.elementAt(index);
        return KlineCtrl();
      },
    );
  }
}

class KlineGridPage extends ConsumerWidget {
  List<String> shareList = [];

  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: shareList.length,
      itemBuilder: (_, index) {
        final state = ref.watch(klineGridProvider(shareList[index]));
        return KlineCtrl();
      },
    );
  }
}
