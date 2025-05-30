import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/store_quote.dart';

class ShareLeftPanel extends StatefulWidget {
  const ShareLeftPanel({super.key});

  @override
  State<ShareLeftPanel> createState() => _ShareLeftPanelState();
}

class _ShareLeftPanelState extends State<ShareLeftPanel> {
  List<Share> _favoriteshares = []; // 自选股
  List<Share> _marketShares = []; // 市场股票
  bool _sortDescending = true; // 排序方式

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 模拟数据加载
    _favoriteshares = StoreQuote.favoriteShares;
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
    return Container(
      width: 300,
      color: Color(0xff000000),
      child: Column(
        children: [
          // 自选股标题
          _buildSectionHeader('自选股', Icons.star),
          // 自选股列表
          Expanded(flex: 3, child: _buildShareList(_favoriteshares)),

          Divider(height: 1),

          // 市场股标题+排序按钮
          _buildSectionHeader(
            '市场行情',
            Icons.trending_up,
            trailing: IconButton(
              icon: Icon(_sortDescending ? Icons.arrow_downward : Icons.arrow_upward),
              onPressed: () {
                setState(() => _sortDescending = !_sortDescending);
                _sortShares();
              },
            ),
          ),

          // 市场股列表
          Expanded(flex: 7, child: _buildShareList(_marketShares)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Widget? trailing}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildShareList(List<Share> shares) {
    return ListView.builder(
      itemCount: shares.length,
      itemExtent: 56, // 固定高度提升性能
      itemBuilder: (context, index) {
        final share = shares[index];
        return ListTile(
          title: Text(share.name),
          subtitle: Text(share.code),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                share.priceNow.toStringAsFixed(2),
                style: TextStyle(color: share.changeRate >= 0 ? Colors.red : Colors.green),
              ),
              Text(
                '${share.changeRate >= 0 ? '' : '-'}${(share.changeRate * 100).toStringAsFixed(2)}%',
                style: TextStyle(color: share.changeRate >= 0 ? Colors.red : Colors.green),
              ),
            ],
          ),
          onTap: () => _onShareSelected(share.code),
        );
      },
    );
  }

  // 通知右侧面板更新股票日K线
  void _onShareSelected(String shareCode) {
    GoRouter.of(context).push('/share/$shareCode');
  }
}
