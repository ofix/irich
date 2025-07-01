// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/provider_backtest.dart
// Purpose:     riverpod provider for backtest page
// Author:      songhuabiao
// Created:     2025-07-01 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/global/backtest.dart';
import 'package:irich/service/backtest_service.dart';
import 'package:irich/service/sql_service.dart';

final backtestProvider = StateNotifierProvider<BacktestNotifier, BacktestState>((ref) {
  return BacktestNotifier();
});

class BacktestState {
  final bool isLoading;
  final BacktestResult? result;
  final String? error;

  BacktestState({this.isLoading = false, this.result, this.error});

  BacktestState copyWith({bool? isLoading, BacktestResult? result, String? error}) {
    return BacktestState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

class BacktestNotifier extends StateNotifier<BacktestState> {
  BacktestNotifier() : super(BacktestState()) {
    _backtestService = BacktestService();
    _dbService = SqlService.instance;
  }

  late final BacktestService _backtestService;
  late final SqlService _dbService;

  // 运行回测
  Future<void> runBacktest(
    List<Factor> factors,
    double initialCapital,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (factors.isEmpty) {
      state = state.copyWith(error: '没有可用的因子数据');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // 获取所有涉及的股票代码
      final stockCodes = factors.map((f) => f.stockCode).toSet().toList();

      // 获取所有股票的市场数据
      final marketDataMap = <String, List<MarketData>>{};

      for (final stockCode in stockCodes) {
        // final marketData = await _dbService.query(
        //   stockCode,
        // );

        // marketDataMap[stockCode] = marketData;
      }

      // 运行回测
      final result = await _backtestService.runBacktest(
        factors,
        marketDataMap,
        initialCapital,
        startDate,
        endDate,
      );

      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      print('Error running backtest: $e');
      state = state.copyWith(isLoading: false, error: '回测时出错: $e');
    }
  }
}
