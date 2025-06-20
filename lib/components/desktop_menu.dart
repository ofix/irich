// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/desktop_menu.dart
// Purpose:     desktop menu
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DesktopMenu extends StatelessWidget {
  const DesktopMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      // decoration: BoxDecoration(
      //   color: Theme.of(context).colorScheme.surface,
      //   border: Border(
      //     right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
      //   ),
      // ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildMenuItem(context, icon: Icons.star, label: '我的', route: '/my'),
          _buildMenuItem(context, icon: Icons.trending_up, label: '行情', route: '/market'),
          _buildMenuItem(context, icon: Icons.search, label: '选股', route: '/discovery'),
          _buildMenuItem(context, icon: Icons.explore, label: '决策', route: '/portfolio'),
          _buildMenuItem(context, icon: Icons.settings, label: '任务', route: '/settings'),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isSelected = GoRouter.of(context).routerDelegate.currentConfiguration.fullPath == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        leading: Icon(icon, size: 20),
        title: Text(label),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        onTap: () => context.go(route),
      ),
    );
  }
}

// class DesktopMenu extends ConsumerWidget {
//   const DesktopMenu({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final router = ref.watch(routerProvider);
//     final currentRoute =
//         router.routerDelegate.currentConfiguration.uri.toString();

//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           const DrawerHeader(
//             decoration: BoxDecoration(color: Colors.blue),
//             child: Text(
//               '东方价值',
//               style: TextStyle(color: Colors.white, fontSize: 24),
//             ),
//           ),
//           _buildListTile(
//             context: context,
//             title: '自选',
//             icon: Icons.star,
//             isSelected: currentRoute == '/favorite',
//             onTap: () => context.go('/favorite'),
//           ),
//           _buildListTile(
//             context: context,
//             title: '行情',
//             icon: Icons.trending_up,
//             isSelected: currentRoute == '/market',
//             onTap: () => context.go('/market'),
//           ),
//           _buildListTile(
//             context: context,
//             title: '选股',
//             icon: Icons.search,
//             isSelected: currentRoute == '/discovery',
//             onTap: () => context.go('/discovery'),
//           ),
//           _buildListTile(
//             context: context,
//             title: '决策',
//             icon: Icons.explore,
//             isSelected: currentRoute == '/portfolio',
//             onTap: () => context.go('/portfolio'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildListTile({
//     required BuildContext context,
//     required String title,
//     required IconData icon,
//     required bool isSelected,
//     required VoidCallback onTap,
//   }) {
//     return ListTile(
//       leading: Icon(icon),
//       title: Text(title),
//       selected: isSelected,
//       selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
//       onTap: onTap,
//     );
//   }
// }
