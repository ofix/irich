// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/pages/backtest/factor_analysis_page.dart
// Purpose:     factor analysis page
// Author:      songhuabiao
// Created:     2025-07-01 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/global/backtest.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/provider_backtest.dart';
import 'package:irich/store/provider_factor.dart';

class FactorAnalysisPage extends ConsumerWidget {
  const FactorAnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(factorAnylysisProvider);
    final factorViewModel = ref.read(factorAnylysisProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('因子分析'),
        actions: [
          if (state.selectedShares.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => factorViewModel.calculateFactors(),
            ),
        ],
      ),
      body:
          state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
              ? Center(child: Text('错误: ${state.error}'))
              : state.factors.isEmpty
              ? _buildEmptyState(context, ref, state.selectedShares)
              : _buildFactorAnalysisContent(context, state),
      floatingActionButton:
          state.factors.isNotEmpty
              ? FloatingActionButton(
                child: const Icon(Icons.play_arrow),
                onPressed: () {
                  _showBacktestDialog(context, ref, state.factors);
                },
              )
              : null,
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, List<Share> selectedStocks) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '已选择 ${selectedStocks.length} 只股票',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          const Text('点击计算按钮进行因子分析'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(factorAnylysisProvider.notifier).calculateFactors(),
            child: const Text('计算因子'),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorAnalysisContent(BuildContext context, FactorAnalysisState state) {
    final factorsByStock = <String, List<Factor>>{};

    // 按股票代码分组因子数据
    for (final factor in state.factors) {
      if (!factorsByStock.containsKey(factor.stockCode)) {
        factorsByStock[factor.stockCode] = [];
      }
      factorsByStock[factor.stockCode]!.add(factor);
    }

    // 找到股票名称映射
    final stockNameMap = {for (final stock in state.selectedShares) stock.code: stock.name};

    return ListView.builder(
      itemCount: factorsByStock.length,
      itemBuilder: (context, index) {
        final stockCode = factorsByStock.keys.elementAt(index);
        final factors = factorsByStock[stockCode]!;
        final stockName = stockNameMap[stockCode] ?? stockCode;

        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$stockName ($stockCode)', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 16),
                _buildFactorChart(factors),
                const SizedBox(height: 16),
                _buildFactorTable(factors),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFactorChart(List<Factor> factors) {
    // 按日期排序
    factors.sort((a, b) => a.date.compareTo(b.date));

    // 准备图表数据
    final roeSpots =
        factors.asMap().entries.map((entry) {
          // return FlSpot(entry.key.toDouble(), entry.value.roe);
        }).toList();

    final profitGrowthSpots =
        factors.asMap().entries.map((entry) {
          // return FlSpot(entry.key.toDouble(), entry.value.profitGrowth);
        }).toList();

    final revenueGrowthSpots =
        factors.asMap().entries.map((entry) {
          // return FlSpot(entry.key.toDouble(), entry.value.revenueGrowth);
        }).toList();

    return SizedBox(
      height: 250,

      // LineChart(
      // LineChartData(
      //   gridData: FlGridData(show: true),
      //   titlesData: FlTitlesData(
      //     bottomTitles: AxisTitles(
      //       sideTitles: SideTitles(
      //         showTitles: true,
      //         getTitlesWidget: (value, meta) {
      //           if (factors.isEmpty) return const Text('');
      //           final index = value.toInt();
      //           if (index < 0 || index >= factors.length) return const Text('');
      //           return Text(factors[index].date.year.toString());
      //         },
      //       ),
      //     ),
      //     leftTitles: AxisTitles(
      //       sideTitles: SideTitles(showTitles: true),
      //     ),
      //   ),
      //   borderData: FlBorderData(show: true),
      //   lineBarsData: [
      //     LineChartBarData(
      //       spots: roeSpots,
      //       isCurved: true,
      //       color: Colors.blue,
      //       dotData: FlDotData(show: true),
      //       belowBarData: BarAreaData(show: false),
      //     ),
      //     LineChartBarData(
      //       spots: profitGrowthSpots,
      //       isCurved: true,
      //       color: Colors.red,
      //       dotData: FlDotData(show: true),
      //       belowBarData: BarAreaData(show: false),
      //     ),
      //     LineChartBarData(
      //       spots: revenueGrowthSpots,
      //       isCurved: true,
      //       color: Colors.green,
      //       dotData: FlDotData(show: true),
      //       belowBarData: BarAreaData(show: false),
      //     ),
      // ],
      // ),
    );
  }

  Widget _buildFactorTable(List<Factor> factors) {
    // 按日期降序排列
    factors.sort((a, b) => b.date.compareTo(a.date));

    return DataTable(
      columns: const [
        DataColumn(label: Text('日期')),
        DataColumn(label: Text('ROE')),
        DataColumn(label: Text('净利润增长')),
        DataColumn(label: Text('营收增长')),
        DataColumn(label: Text('负债率')),
        DataColumn(label: Text('毛利率')),
        DataColumn(label: Text('综合得分')),
      ],
      rows:
          factors.map((factor) {
            return DataRow(
              cells: [
                DataCell(
                  Text('${factor.date.year}-${factor.date.month.toString().padLeft(2, '0')}'),
                ),
                DataCell(Text('${factor.roe.toStringAsFixed(2)}')),
                DataCell(Text('${factor.profitGrowth.toStringAsFixed(2)}')),
                DataCell(Text('${factor.revenueGrowth.toStringAsFixed(2)}')),
                DataCell(Text('${factor.debtRatio.toStringAsFixed(2)}')),
                DataCell(Text('${factor.grossMargin.toStringAsFixed(2)}')),
                DataCell(Text('${factor.compositeScore.toStringAsFixed(2)}')),
              ],
            );
          }).toList(),
    );
  }

  void _showBacktestDialog(BuildContext context, WidgetRef ref, List<Factor> factors) {
    final backtestViewModel = ref.read(backtestProvider.notifier);
    double initialCapital = 1000000;
    DateTime startDate = DateTime(2020, 1, 1);
    DateTime endDate = DateTime.now();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('设置回测参数'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '初始资金'),
                  onChanged: (value) {
                    initialCapital = double.tryParse(value) ?? 1000000;
                  },
                  controller: TextEditingController(text: initialCapital.toString()),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        child: Text(
                          '开始日期: ${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
                        ),
                        onPressed: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2010, 1, 1),
                            lastDate: DateTime.now(),
                          );
                          if (selectedDate != null) {
                            startDate = selectedDate;
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        child: Text(
                          '结束日期: ${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
                        ),
                        onPressed: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime(2010, 1, 1),
                            lastDate: DateTime.now(),
                          );
                          if (selectedDate != null) {
                            endDate = selectedDate;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  backtestViewModel.runBacktest(factors, initialCapital, startDate, endDate);
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/backtest');
                },
                child: const Text('运行回测'),
              ),
            ],
          ),
    );
  }
}
