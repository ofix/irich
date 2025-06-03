// /////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/pages/share/share_page_common.dart
// Purpose:     irich kline panel common functions
// Author:      songhuabiao
// Created:     2025-06-03 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// /////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irich/global/stock.dart';

Widget buildShareList(BuildContext context, List<Share> shares) {
  return ListView.builder(
    itemCount: shares.length,
    itemExtent: 56, // 固定高度提升性能
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

// 通知右侧面板更新股票日K线
void _onShareSelected(BuildContext context, String shareCode) {
  GoRouter.of(context).push('/share/$shareCode');
}
