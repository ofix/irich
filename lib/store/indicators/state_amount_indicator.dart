import 'package:flutter_riverpod/flutter_riverpod.dart';

// 成交额指标状态
class AmountIndicatorState {
  final double maxAmount;
  final List<double> amounts;
  final bool visible;
  final int crossLineIndex;

  AmountIndicatorState({
    required this.maxAmount,
    required this.amounts,
    this.visible = true,
    this.crossLineIndex = -1,
  });
}

// 成交额指标控制器
class AmountIndicatorNotifier extends StateNotifier<AmountIndicatorState> {
  AmountIndicatorNotifier() : super(AmountIndicatorState(maxAmount: 0, amounts: []));

  // 更新成交额数据
  void updateAmounts(List<double> amounts) {
    final max = amounts.reduce((a, b) => a > b ? a : b);
    state = AmountIndicatorState(
      maxAmount: max,
      amounts: amounts,
      visible: state.visible,
      crossLineIndex: state.crossLineIndex,
    );
  }

  // 设置可见性
  void setVisible(bool visible) {
    state = AmountIndicatorState(
      maxAmount: state.maxAmount,
      amounts: state.amounts,
      visible: visible,
      crossLineIndex: state.crossLineIndex,
    );
  }

  // 设置十字线位置
  void setCrossLine(int index) {
    state = AmountIndicatorState(
      maxAmount: state.maxAmount,
      amounts: state.amounts,
      visible: state.visible,
      crossLineIndex: index,
    );
  }
}

// 全局Provider
final amountIndicatorProvider =
    StateNotifierProvider<AmountIndicatorNotifier, AmountIndicatorState>((ref) {
      return AmountIndicatorNotifier();
    });
