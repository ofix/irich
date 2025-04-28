import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/types/stock.dart';

// 分时成交量状态
class MinuteVolumeState {
  final List<double> volumes;
  final List<double> prices;
  final double maxVolume;
  final bool visible;
  final int crossLineIndex;
  final KlineType klineType;

  MinuteVolumeState({
    required this.volumes,
    required this.prices,
    required this.maxVolume,
    required this.klineType,
    this.visible = true,
    this.crossLineIndex = -1,
  });
}

// 分时成交量控制器
class MinuteVolumeNotifier extends StateNotifier<MinuteVolumeState> {
  MinuteVolumeNotifier()
    : super(MinuteVolumeState(volumes: [], prices: [], maxVolume: 0, klineType: KlineType.minute));

  // 更新分时数据
  void updateMinuteData(List<double> volumes, List<double> prices, KlineType type) {
    double max = volumes.isEmpty ? 0 : volumes.reduce((a, b) => a > b ? a : b);
    state = MinuteVolumeState(
      volumes: volumes,
      prices: prices,
      maxVolume: max,
      klineType: type,
      visible: state.visible,
      crossLineIndex: state.crossLineIndex,
    );
  }

  // 设置可见性
  void setVisible(bool visible) {
    state = MinuteVolumeState(
      volumes: state.volumes,
      prices: state.prices,
      maxVolume: state.maxVolume,
      klineType: state.klineType,
      visible: visible,
      crossLineIndex: state.crossLineIndex,
    );
  }

  // 设置十字线位置
  void setCrossLine(int index) {
    state = MinuteVolumeState(
      volumes: state.volumes,
      prices: state.prices,
      maxVolume: state.maxVolume,
      klineType: state.klineType,
      visible: state.visible,
      crossLineIndex: index,
    );
  }

  // 切换K线类型
  void switchKlineType(KlineType type) {
    state = MinuteVolumeState(
      volumes: state.volumes,
      prices: state.prices,
      maxVolume: state.maxVolume,
      klineType: type,
      visible: state.visible,
      crossLineIndex: state.crossLineIndex,
    );
  }
}

// 全局Provider
final minuteVolumeProvider = StateNotifierProvider<MinuteVolumeNotifier, MinuteVolumeState>((ref) {
  return MinuteVolumeNotifier();
});
