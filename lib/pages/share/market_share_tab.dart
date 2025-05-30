import 'package:flutter/material.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/pages/share/share_page_common.dart';
import 'package:irich/store/store_quote.dart';

// 自选股组件
class MarektShareTab extends StatefulWidget {
  const MarektShareTab({super.key});

  @override
  State<MarektShareTab> createState() => _MarektShareTabState();
}

class _MarektShareTabState extends State<MarektShareTab> with AutomaticKeepAliveClientMixin {
  List<Share> _marketShares = []; // 市场股票
  final bool _sortDescending = true; // 排序方式

  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _marketShares = StoreQuote.marketShares;
    _sortShares();
  }

  void _sortShares() {
    setState(() {
      _marketShares.sort(
        (a, b) =>
            _sortDescending
                ? b.changeRate.compareTo(a.changeRate)
                : a.changeRate.compareTo(b.changeRate),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildShareList(context, _marketShares);
  }
}
