// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/pages/backtest/backtest_page.dart
// Purpose:     stock backtest page
// Author:      songhuabiao
// Created:     2025-07-01 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/global/backtest.dart';
import 'package:irich/store/provider_backtest.dart';

class BacktestPage extends ConsumerWidget {
  const BacktestPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(backtestProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('回测结果')),
      body:
          state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
              ? Center(child: Text('错误: ${state.error}'))
              : state.result == null
              ? const Center(child: Text('没有回测结果'))
              : _buildBacktestResultContent(context, state.result!),
    );
  }

  Widget _buildBacktestResultContent(BuildContext context, BacktestResult result) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPerformanceSummary(context, result),
        const SizedBox(height: 32),
        _buildEquityCurveChart(result),
        const SizedBox(height: 32),
        _buildTradeTable(result),
      ],
    );
  }

  Widget _buildPerformanceSummary(BuildContext context, BacktestResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('回测绩效摘要', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
              border: TableBorder.all(color: Colors.grey.shade300),
              children: [
                _buildTableRow('初始资金', '¥${result.initialCapital.toStringAsFixed(2)}'),
                _buildTableRow('最终资金', '¥${result.finalCapital.toStringAsFixed(2)}'),
                _buildTableRow('总收益率', '${(result.totalReturn * 100).toStringAsFixed(2)}%'),
                _buildTableRow('年化收益率', '${(result.annualizedReturn * 100).toStringAsFixed(2)}%'),
                _buildTableRow('最大回撤', '${(result.maxDrawdown * 100).toStringAsFixed(2)}%'),
                _buildTableRow('夏普比率', result.sharpeRatio.toStringAsFixed(2)),
                _buildTableRow('胜率', '${(result.winRate * 100).toStringAsFixed(2)}%'),
                _buildTableRow('总交易次数', result.totalTrades.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(8.0), child: Text(label)),
        Padding(padding: const EdgeInsets.all(8.0), child: Text(value)),
      ],
    );
  }

  Widget _buildEquityCurveChart(BacktestResult result) {
    // 确保有足够的数据点
    if (result.portfolioValues.length < 2) {
      return const Text('数据不足，无法绘制权益曲线');
    }

    // 转换为FlSpot
    final spots =
        result.portfolioValues.map((point) {
          // return FlSpot(point.date.millisecondsSinceEpoch.toDouble(), point.value);
        }).toList();

    // 找到x轴的最小值和最大值
    final minX = double.infinity;
    final maxX = double.negativeInfinity;

    // 找到y轴的最小值和最大值
    // final minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    // final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('权益曲线'),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              // child: LineChart(
              //   LineChartData(
              //     gridData: FlGridData(show: true),
              //     titlesData: FlTitlesData(
              //       bottomTitles: AxisTitles(
              //         sideTitles: SideTitles(
              //           showTitles: true,
              //           getTitlesWidget: (value, meta) {
              //             final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              //             return Text('${date.year}-${date.month.toString().padLeft(2, '0')}');
              //           },
              //         ),
              //       ),
              //       leftTitles: AxisTitles(sideTitles: SideTitles(show: true)),
              //     ),
              //     borderData: FlBorderData(show: true),
              //     minX: minX,
              //     maxX: maxX,
              //     minY: minY * 0.95,
              //     maxY: maxY * 1.05,
              //     lineBarsData: [
              //       LineChartBarData(
              //         spots: spots,
              //         isCurved: true,
              //         color: Colors.blue,
              //         dotData: FlDotData(show: false),
              //         belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
              //       ),
              //     ],
              //   ),
              // ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeTable(BacktestResult result) {
    final trades = result.trades;

    if (trades.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('没有交易记录')));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('交易记录 (共${trades.length}笔)'),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('股票代码')),
                  DataColumn(label: Text('买入日期')),
                  DataColumn(label: Text('买入价格')),
                  DataColumn(label: Text('卖出日期')),
                  DataColumn(label: Text('卖出价格')),
                  DataColumn(label: Text('盈亏')),
                  DataColumn(label: Text('盈亏率')),
                ],
                rows:
                    trades.map((trade) {
                      final profitRate =
                          ((trade.sellPrice - trade.buyPrice) / trade.buyPrice) * 100;
                      final profitColor = trade.profit >= 0 ? Colors.green : Colors.red;

                      return DataRow(
                        cells: [
                          DataCell(Text(trade.stockCode)),
                          DataCell(
                            Text(
                              '${trade.buyDate.year}-${trade.buyDate.month.toString().padLeft(2, '0')}-${trade.buyDate.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                          DataCell(Text(trade.buyPrice.toStringAsFixed(2))),
                          DataCell(
                            Text(
                              '${trade.sellDate.year}-${trade.sellDate.month.toString().padLeft(2, '0')}-${trade.sellDate.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                          DataCell(Text(trade.sellPrice.toStringAsFixed(2))),
                          DataCell(
                            Text(
                              '${trade.profit >= 0 ? '+' : ''}${trade.profit.toStringAsFixed(2)}',
                              style: TextStyle(color: profitColor),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${profitRate >= 0 ? '+' : ''}${profitRate.toStringAsFixed(2)}%',
                              style: TextStyle(color: profitColor),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
