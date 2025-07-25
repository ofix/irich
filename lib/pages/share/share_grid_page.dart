import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/components/kline_ctrl/mini_kline_ctrl.dart';
import 'package:irich/components/rich_radio_button_group.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/provider_kline_ctrl.dart';
import 'package:irich/store/state_quote.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/theme/stock_colors.dart';

enum ShareGridLayout { twoByTwo, threeByTwo, threeByThree, fourByFour }

class ShareGridPage extends ConsumerStatefulWidget {
  const ShareGridPage({super.key});

  @override
  ConsumerState<ShareGridPage> createState() => _ShareGridPageState();
}

class _ShareGridPageState extends ConsumerState<ShareGridPage> {
  late final FocusNode _focusNode;
  List<String> shares = [];
  ShareGridLayout layout = ShareGridLayout.twoByTwo;
  late Share activeShare;
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.requestFocus();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final stockColors = Theme.of(context).extension<StockColors>()!;
    return buildGridView(stockColors);
  }

  Widget buildGridView(StockColors stockColors) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // final parentWidth = constraints.maxWidth; // 父容器可用宽度
        Size size = Size(constraints.maxWidth, constraints.maxHeight);
        return Column(
          children: [
            // K线类型切换
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [_buildKlineTypeTabs()]),
                Row(
                  children: [
                    _buildMinuteKlineWndMode(), // 分时窗口模式选择
                    SizedBox(width: 8),
                    _buildFavoriteButton(stockColors), // 自选按钮
                  ],
                ),
              ],
            ),
            buildKlineGrid(stockColors, shares),
          ],
        );
      },
    );
  }

  /// K线类别组件
  Widget _buildKlineTypeTabs() {
    return RichRadioButtonGroup(
      options: ["日K", "周K", "月K", "季K", "年K", "分时", "五日"],
      onChanged: (value) {
        _onKlineTypeChanged(value);
      },
      height: KlineCtrlLayout.titleBarHeight,
    );
  }

  /// 切换股票类别
  void _onKlineTypeChanged(String value) async {
    final klineType = klineTypeMap[value]!;
    ref.read(miniKlineCtrlProviders(value).notifier).changeKlineType(klineType);
  }

  Widget _buildMinuteKlineWndMode() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<MinuteKlineWndMode>(
        value: MinuteKlineWndMode.ema,
        hint: Text('请选择模式'),
        items:
            MinuteKlineWndMode.values.map((mode) {
              return DropdownMenuItem<MinuteKlineWndMode>(
                value: mode,
                child: Text(mode.displayName),
              );
            }).toList(),
        onChanged: (newMode) {
          if (newMode != null) {
            debugPrint("newMode: ${newMode.displayName}");
            ref.read(klineCtrlProvider.notifier).changeMinuteWndMode(newMode);
          }
        },
        //dropdownColor: Colors.transparent, // Remove dropdown background color
        icon: Icon(Icons.arrow_drop_down), // Custom icon if needed
        style: TextStyle(
          color: Colors.blue, // Custom text color
          // Add other text styling as needed
        ),
        elevation: 0, // Remove shadow
      ),
    );
  }

  // 自选按钮组件
  Widget _buildFavoriteButton(StockColors stockColors) {
    return // 自选按钮
    MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _onToggleFavoriteButton,
        child: Row(
          children: [
            Icon(
              activeShare.isFavorite ? Icons.remove : Icons.add,
              size: 18,
              color: stockColors.hilight,
            ),
            Text(
              "自选",
              style: TextStyle(
                backgroundColor: Colors.transparent,
                color: stockColors.hilight,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  /// 添加股票到自选池
  void _onToggleFavoriteButton() {
    final shareCode = ref.read(currentShareCodeProvider);
    Share share = StoreQuote.query(shareCode)!;
    share.isFavorite = !share.isFavorite;
    if (share.isFavorite) {
      ref.read(watchShareListProvider.notifier).add(shareCode);
    } else {
      ref.read(watchShareListProvider.notifier).remove(shareCode);
    }
  }

  Widget buildKlineGrid(StockColors stockColors, List<String> shares) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
      itemCount: shares.length,
      itemBuilder: (_, index) {
        return MiniKlineCtrl(shareCode: shares[index]);
      },
    );
  }
}
