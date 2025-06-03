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
import 'package:irich/pages/share/share_page_common.dart';
import 'package:irich/store/store_quote.dart';

// 自选股组件
class FavoriteShareTab extends StatefulWidget {
  const FavoriteShareTab({super.key});

  @override
  State<FavoriteShareTab> createState() => _FavoriteShareTabState();
}

class _FavoriteShareTabState extends State<FavoriteShareTab> with AutomaticKeepAliveClientMixin {
  List<Share> _favoriteshares = []; // 自选股

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _favoriteshares = StoreQuote.favoriteShares;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_favoriteshares.isEmpty) {
      return _buildEmptyView(context);
    }
    return buildShareList(context, _favoriteshares);
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无自选股', style: TextStyle(color: Colors.grey, fontSize: 16)),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => GoRouter.of(context).push('/share/search'),
            child: Text('添加自选股'),
          ),
        ],
      ),
    );
  }
}
