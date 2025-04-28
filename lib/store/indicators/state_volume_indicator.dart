import 'package:flutter_riverpod/flutter_riverpod.dart';

// 成交量指标状态
class VolumeIndicatorState {
  final double maxVolume;
  final List<double> volumes;
  final bool visible;
  final int crossLineIndex;
  final List<bool> isUpList; // 用于判断涨跌

  VolumeIndicatorState({
    required this.maxVolume,
    required this.volumes,
    required this.isUpList,
    this.visible = true,
    this.crossLineIndex = -1,
  });
}

// 成交量指标控制器
class VolumeIndicatorNotifier extends StateNotifier<VolumeIndicatorState> {
  VolumeIndicatorNotifier() : super(VolumeIndicatorState(maxVolume: 0, volumes: [], isUpList: []));

  // 更新成交量数据
  void updateVolumes(List<double> volumes, List<bool> isUpList) {
    double max = volumes.isEmpty ? 0 : volumes.reduce((a, b) => a > b ? a : b);
    state = VolumeIndicatorState(
      maxVolume: max,
      volumes: volumes,
      isUpList: isUpList,
      visible: state.visible,
      crossLineIndex: state.crossLineIndex,
    );
  }

  // 设置可见性
  void setVisible(bool visible) {
    state = VolumeIndicatorState(
      maxVolume: state.maxVolume,
      volumes: state.volumes,
      isUpList: state.isUpList,
      visible: visible,
      crossLineIndex: state.crossLineIndex,
    );
  }

  // 设置十字线位置
  void setCrossLine(int index) {
    state = VolumeIndicatorState(
      maxVolume: state.maxVolume,
      volumes: state.volumes,
      isUpList: state.isUpList,
      visible: state.visible,
      crossLineIndex: index,
    );
  }
}

// 全局Provider
final volumeIndicatorProvider =
    StateNotifierProvider<VolumeIndicatorNotifier, VolumeIndicatorState>((ref) {
      return VolumeIndicatorNotifier();
    });
