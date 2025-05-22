// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/ui/portfolio page.dart
// Purpose:     portfolio page
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/desktop_layout.dart';
import 'package:irich/pages/portfolio/portfolio_view.dart';

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return DesktopLayout(
      child: Container(padding: const EdgeInsets.all(24), child: PortfolioView(title: "决策页面")),
    );
  }
}
