import 'package:flutter_riverpod/flutter_riverpod.dart';

// 换手率指标状态
class TurnoverRateState {
  final double maxTurnoverRate;
  final List<double> turnoverRates;
  final List<bool> isUpList; // 用于判断涨跌
  final bool visible;
  final int crossLineIndex;

  TurnoverRateState({
    required this.maxTurnoverRate,
    required this.turnoverRates,
    required this.isUpList,
    this.visible = true,
    this.crossLineIndex = -1,
  });
}

// 换手率指标控制器
class TurnoverRateNotifier extends StateNotifier<TurnoverRateState> {
  TurnoverRateNotifier()
    : super(TurnoverRateState(maxTurnoverRate: 0, turnoverRates: [], isUpList: []));

  // 更新换手率数据
  void updateTurnoverRates(List<double> rates, List<bool> isUpList) {
    double max = rates.isEmpty ? 0 : rates.reduce((a, b) => a > b ? a : b);
    state = TurnoverRateState(
      maxTurnoverRate: max,
      turnoverRates: rates,
      isUpList: isUpList,
      visible: state.visible,
      crossLineIndex: state.crossLineIndex,
    );
  }

  // 设置可见性
  void setVisible(bool visible) {
    state = TurnoverRateState(
      maxTurnoverRate: state.maxTurnoverRate,
      turnoverRates: state.turnoverRates,
      isUpList: state.isUpList,
      visible: visible,
      crossLineIndex: state.crossLineIndex,
    );
  }

  // 设置十字线位置
  void setCrossLine(int index) {
    state = TurnoverRateState(
      maxTurnoverRate: state.maxTurnoverRate,
      turnoverRates: state.turnoverRates,
      isUpList: state.isUpList,
      visible: state.visible,
      crossLineIndex: index,
    );
  }
}

// 全局Provider
final turnoverRateProvider = StateNotifierProvider<TurnoverRateNotifier, TurnoverRateState>((ref) {
  return TurnoverRateNotifier();
});
