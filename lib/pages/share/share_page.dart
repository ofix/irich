import 'package:flutter/material.dart';
import 'package:irich/global/stock.dart';

// 个股面板，左侧（自选股+市场个股），右侧日/周/月K线图
class SharePage extends StatefulWidget {
  final String title;
  const SharePage({super.key, this.title = "个股详情"});

  @override
  State<SharePage> createState() => SharePageState();
}

class SharePageState extends State<SharePage> {
  String? shareCode;

  @override
  void initState() {
    super.initState();
    shareCode = "";
  }

  void showShare(Share share) {
    shareCode = share.code;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
