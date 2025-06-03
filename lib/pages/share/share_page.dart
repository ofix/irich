// /////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/pages/share/share_page.dart
// Purpose:     irich share page
// Author:      songhuabiao
// Created:     2025-06-03 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// /////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/desktop_layout.dart';
import 'package:irich/pages/share/share_left_panel.dart';
import 'package:irich/pages/share/share_right_panel.dart';

// 个股面板，左侧（自选股+市场个股），右侧日/周/月K线图
class SharePage extends StatefulWidget {
  final String title;
  final String shareCode;
  const SharePage({super.key, required this.shareCode, this.title = "个股详情"});

  @override
  State<SharePage> createState() => SharePageState();
}

class SharePageState extends State<SharePage> {
  late String currentShareCode;
  @override
  void initState() {
    super.initState();
    currentShareCode = widget.shareCode;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(SharePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shareCode != widget.shareCode) {
      setState(() {
        currentShareCode = widget.shareCode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesktopLayout(
      child: Row(
        children: [
          ShareLeftPanel(),
          VerticalDivider(width: 1),
          ShareRightPanel(shareCode: currentShareCode),
        ],
      ),
    );
  }
}
