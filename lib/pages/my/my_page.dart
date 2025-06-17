// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/ui/favorite page.dart
// Purpose:     favorite page
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/desktop_layout.dart';
import 'package:irich/pages/my/my_view.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key, required this.title});
  final String title;

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  @override
  Widget build(BuildContext context) {
    return DesktopLayout(
      child: Container(padding: const EdgeInsets.all(24), child: MyView(title: "自选页面")),
    );
  }
}
