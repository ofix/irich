import 'package:flutter/material.dart';
import 'package:irich/components/desktop_layout.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/pages/share/share_left_panel.dart';
import 'package:irich/pages/share/share_right_panel.dart';
import 'package:irich/store/store_quote.dart';

// 个股面板，左侧（自选股+市场个股），右侧日/周/月K线图
class SharePage extends StatefulWidget {
  final String title;
  final String shareCode;
  const SharePage({super.key, required this.shareCode, this.title = "个股详情"});

  @override
  State<SharePage> createState() => SharePageState();
}

class SharePageState extends State<SharePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Share? share = StoreQuote.query(widget.shareCode);
    return DesktopLayout(
      child: Row(
        children: [
          ShareLeftPanel(),
          VerticalDivider(width: 1),
          ShareRightPanel(currentShare: share),
        ],
      ),
    );
  }
}
