// /////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/pages/share/favorite_share_tab.dart
// Purpose:     irich favorite shares tab view
// Author:      songhuabiao
// Created:     2025-06-03 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// /////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/state_quote.dart';
import 'package:irich/store/store_quote.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoriteShareTab extends ConsumerStatefulWidget {
  const FavoriteShareTab({super.key});

  @override
  ConsumerState<FavoriteShareTab> createState() => _FavoriteShareTabState();
}

class _FavoriteShareTabState extends ConsumerState<FavoriteShareTab>
    with AutomaticKeepAliveClientMixin {
  List<Share> _favoriteshares = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint('FavoriteShareTab initState');
    _favoriteshares = StoreQuote.favoriteShares;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final favoirteTabScrollController = ref.watch(favoriteTabScrollControllerProvider);

    Widget buildShareList(BuildContext context, List<Share> shares) {
      return ListView.builder(
        controller: favoirteTabScrollController,
        itemCount: shares.length,
        itemExtent: 56,
        itemBuilder: (context, index) {
          final share = shares[index];
          return ListTile(
            title: Text(share.name),
            subtitle: Text(share.code),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  share.priceNow.toStringAsFixed(2),
                  style: TextStyle(color: share.changeRate >= 0 ? Colors.red : Colors.green),
                ),
                Text(
                  '${share.changeRate >= 0 ? '' : '-'}${(share.changeRate * 100).toStringAsFixed(2)}%',
                  style: TextStyle(color: share.changeRate >= 0 ? Colors.red : Colors.green),
                ),
              ],
            ),
            onTap: () => _onShareSelected(context, share.code),
          );
        },
      );
    }

    if (_favoriteshares.isEmpty) {
      return _buildEmptyView(context);
    }
    return buildShareList(context, _favoriteshares);
  }

  void _onShareSelected(BuildContext context, String shareCode) {
    // 2. 跳转前强制设置 Tab 为自选股（索引为1）
    ref.read(shareTabIndexProvider.notifier).state = 1;
    ref.read(currentShareCodeProvider.notifier).select(shareCode);
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 48, color: const Color.fromARGB(255, 65, 64, 64)),
          const SizedBox(height: 16),
          Text('暂无自选股', style: TextStyle(color: Color.fromARGB(255, 24, 24, 24), fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => GoRouter.of(context).push('/share/search'),
            child: const Text('添加自选股'),
          ),
        ],
      ),
    );
  }
}
