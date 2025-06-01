import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_ctrl.dart';

class ShareRightPanel extends StatefulWidget {
  final String shareCode;

  const ShareRightPanel({super.key, required this.shareCode});

  @override
  State<ShareRightPanel> createState() => _ShareRightPanelState();
}

class _ShareRightPanelState extends State<ShareRightPanel> {
  @override
  Widget build(BuildContext context) {
    return Expanded(child: KlineCtrl(shareCode: widget.shareCode));
  }
}
