import 'package:flutter/material.dart';
import 'package:irich/components/kline_ctrl/kline_ctrl.dart';
import 'package:irich/global/stock.dart';

class ShareRightPanel extends StatefulWidget {
  final Share? currentShare;

  const ShareRightPanel({super.key, this.currentShare});

  @override
  State<ShareRightPanel> createState() => ShareRightPanelState();
}

class ShareRightPanelState extends State<ShareRightPanel> {
  KlineType _klineType = KlineType.day; // 默认日K线
  Share? _selectedShare; // 当前选中的股票
  List<Share> _shares = []; // 股票列表

  @override
  void didUpdateWidget(ShareRightPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentShare != oldWidget.currentShare) {
      _loadChartData();
    }
  }

  Future<void> _loadChartData() async {
    if (widget.currentShare == null) return;

    // setState(() => _shares = data);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // 股票信息标题
          _buildShareHeader(),
          // 图表类型切换
          _buildChartTypeSelector(),
          // K线图表主体
          Expanded(child: Padding(padding: EdgeInsets.all(8), child: KlineCtrl())),
          // 技术指标选择
          _buildTechIndicators(),
        ],
      ),
    );
  }

  Widget _buildShareHeader() {
    final share = widget.currentShare;
    return Container(
      padding: EdgeInsets.all(12),
      color: Colors.grey[200],
      child: Row(
        children: [
          Text(share?.name ?? '请选择股票', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(width: 10),
          Text(share?.code ?? ''),
          Spacer(),
          if (share != null) ...[
            Text(
              share.priceNow.toStringAsFixed(2),
              style: TextStyle(
                color: share.changeRate >= 0 ? Colors.red : Colors.green,
                fontSize: 18,
              ),
            ),
            SizedBox(width: 10),
            Text(
              '${share.changeRate >= 0 ? '+' : ''}${share.changeRate.toStringAsFixed(2)}%',
              style: TextStyle(color: share.changeRate >= 0 ? Colors.red : Colors.green),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return Row(
      children: [
        _buildChartTypeButton('分时', KlineType.minute),
        _buildChartTypeButton('日K', KlineType.day),
        _buildChartTypeButton('周K', KlineType.week),
        _buildChartTypeButton('月K', KlineType.month),
        _buildChartTypeButton('5日', KlineType.fiveDay),
      ],
    );
  }

  Widget _buildChartTypeButton(String text, KlineType type) {
    return TextButton(
      style: TextButton.styleFrom(foregroundColor: _klineType == type ? Colors.blue : Colors.grey),
      child: Text(text),
      onPressed: () {
        setState(() => _klineType = type);
        _loadChartData();
      },
    );
  }

  Widget _buildTechIndicators() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          Chip(label: Text('MACD')),
          Chip(label: Text('KDJ')),
          Chip(label: Text('RSI')),
          Chip(label: Text('BOLL')),
        ],
      ),
    );
  }
}
