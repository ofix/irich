// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/router/app_router.dart
// Purpose:     global application router
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:go_router/go_router.dart';
import 'package:irich/ui/discovery/discovery_page.dart';
import 'package:irich/ui/market/market_page.dart';
import 'package:irich/ui/portfolio/portfolio_page.dart';
import 'package:irich/ui/favorite/favorite_page.dart';

// 禁用GoRouter默认页面切换动画
final appRouter = GoRouter(
  initialLocation: '/market',
  routes: [
    GoRoute(
      path: '/portfolio',
      pageBuilder:
          (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const PortfolioPage(title: "决策")),
    ),
    GoRoute(
      path: '/market',
      pageBuilder:
          (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const MarketPage(title: '行情')),
    ),
    GoRoute(
      path: '/favorite',
      pageBuilder:
          (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const FavoritePage(title: '自选')),
    ),
    GoRoute(
      path: '/discovery',
      pageBuilder:
          (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const DiscoveryPage(title: '选股')),
    ),
  ],
);

// 开启页面切换动画
// final appRouter = GoRouter(
//   initialLocation: '/favorite',
//   routes: [
//     GoRoute(
//       path: '/portfolio',
//       builder: (context, state) => const PortfolioPage(title: "决策"),
//     ),
//     GoRoute(
//       path: '/market',
//       builder: (context, state) => const MarketPage(title: '行情'),
//     ),
//     GoRoute(
//       path: '/favorite',
//       builder: (context, state) => const FavoritePage(title: '自选'),
//     ),
//     GoRoute(
//       path: '/discovery',
//       builder: (context, state) => const DiscoveryPage(title: '选股'),
//     ),
//   ],
// );
