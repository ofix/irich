// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/provider_factor.dart
// Purpose:     riverpod provider for factor analysis page
// Author:      songhuabiao
// Created:     2025-07-01 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/global/backtest.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/service/factor_service.dart';
import 'package:irich/service/sql_service.dart';

final factorAnylysisProvider = StateNotifierProvider<FactorAnalysisNotifier, FactorAnalysisState>((
  ref,
) {
  return FactorAnalysisNotifier();
});

class FactorAnalysisState {
  final bool isLoading;
  final List<Share> selectedShares;
  final List<Factor> factors;
  final String? error;

  FactorAnalysisState({
    this.isLoading = false,
    this.selectedShares = const [],
    this.factors = const [],
    this.error,
  });

  FactorAnalysisState copyWith({
    bool? isLoading,
    List<Share>? selectedStocks,
    List<Factor>? factors,
    String? error,
  }) {
    return FactorAnalysisState(
      isLoading: isLoading ?? this.isLoading,
      selectedShares: selectedStocks ?? this.selectedShares,
      factors: factors ?? this.factors,
      error: error ?? this.error,
    );
  }
}

class FactorAnalysisNotifier extends StateNotifier<FactorAnalysisState> {
  FactorAnalysisNotifier() : super(FactorAnalysisState()) {
    _factorService = FactorService();
    _dbService = SqlService.instance;
  }

  late final FactorService _factorService;
  late final SqlService _dbService;

  // 选择股票进行因子分析
  void selectStocks(List<Share> stocks) {
    state = state.copyWith(selectedStocks: stocks, factors: [], error: null);
  }

  // 计算因子
  Future<void> calculateFactors() async {
    if (state.selectedShares.isEmpty) {
      state = state.copyWith(error: '请先选择股票');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final allFactors = <Factor>[];

      for (final stock in state.selectedShares) {
        // 获取财务数据
        final financialData = await _dbService.getFinancialData(stock.code);

        // 获取市场数据
        final marketData = await _dbService.getMarketData(
          stock.code,
          startDate: DateTime(2018, 1, 1),
          endDate: DateTime.now(),
        );

        // 计算因子
        final factors = await _factorService.calculateFactors(
          stock.code,
          financialData,
          marketData,
        );

        allFactors.addAll(factors);
      }

      // 标准化因子
      final normalizedFactors = _factorService.normalizeFactors(allFactors);

      state = state.copyWith(isLoading: false, factors: normalizedFactors);
    } catch (e) {
      print('Error calculating factors: $e');
      state = state.copyWith(isLoading: false, error: '计算因子时出错: $e');
    }
  }
}
