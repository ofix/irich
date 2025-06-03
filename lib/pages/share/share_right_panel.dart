// /////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/pages/share/share_right_panel.dart
// Purpose:     irich share right panel
// Author:      songhuabiao
// Created:     2025-06-03 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// /////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_ctrl.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/store_quote.dart';

class ShareRightPanel extends StatefulWidget {
  final String shareCode;
  final Share? share;
  ShareRightPanel({super.key, required this.shareCode}) : share = StoreQuote.query(shareCode);

  @override
  State<ShareRightPanel> createState() => _ShareRightPanelState();
}

class _ShareRightPanelState extends State<ShareRightPanel> {
  @override
  Widget build(BuildContext context) {
    return Expanded(child: KlineCtrl(share: widget.share!));
  }
}
