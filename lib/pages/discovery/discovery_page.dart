// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/ui/discovery_page.dart
// Purpose:     discovery page
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/desktop_layout.dart';
import 'package:irich/pages/discovery/discovery_view.dart';

class DiscoveryPage extends StatelessWidget {
  const DiscoveryPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return DesktopLayout(
      child: Container(padding: const EdgeInsets.all(24), child: DiscoveryView(title: "选股页面")),
    );
  }
}
