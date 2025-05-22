// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/ui/discovery_view.dart
// Purpose:     discovery view
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/store/state_favorite.dart';

class FavoriteView extends ConsumerWidget {
  const FavoriteView({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('自选页面: You have pushed the button this many times:'),
          Text('$count', style: Theme.of(context).textTheme.headlineMedium),
          MaterialButton(
            onPressed: () => ref.read(counterProvider.notifier).state++,
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.all(16.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            child: const Text('增加'),
          ),
        ],
      ),
    );
  }
}
