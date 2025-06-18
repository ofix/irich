// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/ui/discovery_view.dart
// Purpose:     discovery view
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/dynamic_panel_ctrl/dynamic_panel_ctrl.dart';

class MyView extends ConsumerWidget {
  const MyView({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DynamicPanelCtrl();
  }
}
