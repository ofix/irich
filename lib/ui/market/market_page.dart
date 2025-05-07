import 'dart:async';
import 'package:flutter/material.dart';
import 'package:irich/components/desktop_layout.dart';
import 'package:irich/components/progress_popup.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/utils/helper.dart';
import 'package:trina_grid/trina_grid.dart';

class MarketPage extends StatefulWidget {
  final String title;
  const MarketPage({super.key, required this.title});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  late List<TrinaRow> rows;
  late List<TrinaColumn> cols;
  late List<Share> shares;

  Timer? timer;
  Color? backgroundColor;

  late TrinaGridStateManager stateManager;

  @override
  void initState() {
    super.initState();
    rows = [];
    cols = [];
    shares = [];
    _load();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopLayout(
      child: Container(
        padding: const EdgeInsets.all(24),
        child:
            rows.isEmpty
                ? Text("")
                : Container(
                  padding: const EdgeInsets.all(16),
                  child: TrinaGrid(
                    configuration: TrinaGridConfiguration(
                      style: TrinaGridStyleConfig(
                        gridBackgroundColor: Color(0xff000000),
                        enableColumnBorderVertical: true,
                        activatedBorderColor: Colors.transparent,
                        inactivatedBorderColor: const Color.fromARGB(255, 39, 38, 38),
                        rowColor: Color(0xff000000),
                        activatedColor: Color(0xff284468),
                        borderColor: const Color.fromARGB(255, 39, 38, 38),
                        cellCheckedColor: Colors.transparent,
                        columnTextStyle: TextStyle(color: Color(0xFFFFFFFF)),
                        cellTextStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                        rowHeight: 28,
                      ),
                    ),
                    columns: cols,
                    rows: rows,
                    onLoaded: (TrinaGridOnLoadedEvent event) {
                      stateManager = event.stateManager;
                      debugPrint("TrinaGrid inited");
                    },
                  ),
                ),
      ),
    );
  }

  Future<void> _load() async {
    // 检查行业/概念/地域板块数据本地文件是否存在
    final isReady = await StoreQuote.isQuoteExtraDataReady();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isReady) {
        // 不存在就显示弹窗，并显示进度条信息
        showProgressPopup(context, StoreQuote.progressStream);
      }
      backgroundColor = Theme.of(context).primaryColor;
    });
    // 异步加载行情数据,初始加载还要额外加载概念/地域/行业映射数据
    await StoreQuote.load();
    shares = StoreQuote.shares;
    rows = _buildRows(shares);
    cols = _buildColumns();
    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      hideProgressPopup(context);
    });
    // _startTimer();
  }

  // 定时加载行情数据
  Future<void> _startTimer() async {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _load();
      shares = StoreQuote.shares;
      rows = _buildRows(shares);
      // cols = _buildColumns();
      stateManager.removeAllRows();
      stateManager.appendRows(rows);
      setState(() {});
    });
  }

  // 构建表格标题栏
  List<TrinaColumn> _buildColumns() {
    final fields = [
      ['', 'id', 64, TrinaColumnTextAlign.right],
      ['代码', 'code', 100, TrinaColumnTextAlign.right],
      ['名称', 'name', 100, TrinaColumnTextAlign.left],
      ['涨幅%', 'changeRate', 100, TrinaColumnTextAlign.right],
      ['现价', 'priceNow', 100, TrinaColumnTextAlign.right],
      ['昨收', 'priceYesterdayClose', 100, TrinaColumnTextAlign.right],
      ['今开', 'priceOpen', 100, TrinaColumnTextAlign.right],
      ['最高', 'priceMax', 100, TrinaColumnTextAlign.right],
      ['最低', 'priceMin', 100, TrinaColumnTextAlign.right],
      ['成交量', 'volume', 100, TrinaColumnTextAlign.right],
      ['成交额', 'amount', 100, TrinaColumnTextAlign.right],
      ['换手', 'turnoverRate', 100, TrinaColumnTextAlign.right],
      ['振幅', 'priceAmplitude', 100, TrinaColumnTextAlign.right],
      ['量比', 'qrr', 100, TrinaColumnTextAlign.right],
      ['行业', 'industryName', 100, TrinaColumnTextAlign.left],
      ['省份', 'province', 100, TrinaColumnTextAlign.left],
    ];

    return List.generate(fields.length, (index) {
      final field = fields[index];
      return TrinaColumn(
        title: field[0] as String,
        field: field[1] as String,
        type: TrinaColumnType.text(),
        width: (field[2] as int).toDouble(),
        readOnly: true,
        titleTextAlign: field[3] as TrinaColumnTextAlign,
      );
    });
  }

  // 构建单元格
  Widget _buildCell(TrinaCellRendererContext ctx, Color clr, TextAlign textAlign) {
    return Text(ctx.cell.value.toString(), style: TextStyle(color: clr), textAlign: textAlign);
  }

  Widget _buildPriceCell(TrinaCellRendererContext ctx, bool isUp, TextAlign textAlign) {
    if (isUp) {
      return _buildCell(ctx, Colors.red, TextAlign.right);
    } else {
      return _buildCell(ctx, Colors.green, TextAlign.right);
    }
  }

  // 构建表格行
  List<TrinaRow> _buildRows(List<Share> shares) {
    List<TrinaRow> newRows = [];
    int i = 0;
    Color greyColor = const Color.fromARGB(255, 249, 240, 240);
    for (final share in shares) {
      i++;
      newRows.add(
        TrinaRow(
          cells: {
            'id': TrinaCell(
              value: i.toString(),
              renderer: (ctx) {
                return _buildCell(ctx, greyColor, TextAlign.right);
              },
            ),
            'code': TrinaCell(
              value: share.code,
              renderer: (ctx) {
                return _buildCell(ctx, greyColor, TextAlign.right);
              },
            ),
            'name': TrinaCell(
              value: share.name,
              renderer: (ctx) {
                return _buildCell(ctx, Colors.blue, TextAlign.left);
              },
            ),
            'changeRate': TrinaCell(
              value: "${(share.changeRate * 100).toStringAsFixed(2)}%",
              renderer: (ctx) {
                return _buildPriceCell(ctx, share.changeRate > 0, TextAlign.right);
              },
            ),
            'priceNow': TrinaCell(
              value: share.priceNow.toStringAsFixed(2),
              renderer: (ctx) {
                return _buildPriceCell(ctx, share.changeRate > 0, TextAlign.right);
              },
            ),
            'priceYesterdayClose': TrinaCell(
              value: share.priceYesterdayClose.toStringAsFixed(2),
              renderer: (ctx) {
                return _buildPriceCell(ctx, share.changeRate > 0, TextAlign.right);
              },
            ),
            'priceOpen': TrinaCell(
              value: share.priceOpen.toStringAsFixed(2),
              renderer: (ctx) {
                return _buildPriceCell(ctx, share.changeRate > 0, TextAlign.right);
              },
            ),
            'priceMax': TrinaCell(
              value: share.priceMax.toStringAsFixed(2),
              renderer: (ctx) {
                return _buildPriceCell(ctx, share.changeRate > 0, TextAlign.right);
              },
            ),
            'priceMin': TrinaCell(
              value: share.priceMin.toStringAsFixed(2),
              renderer: (ctx) {
                return _buildPriceCell(ctx, share.changeRate > 0, TextAlign.right);
              },
            ),
            'amount': TrinaCell(
              value: Helper.richUnit(share.amount),
              renderer: (ctx) {
                return _buildCell(ctx, greyColor, TextAlign.right);
              },
            ),
            'volume': TrinaCell(
              value: Helper.richUnit(share.volume.toDouble()),
              renderer: (ctx) {
                return _buildCell(ctx, greyColor, TextAlign.right);
              },
            ),
            'turnoverRate': TrinaCell(
              value: "${share.turnoverRate.toStringAsFixed(2)}%",
              renderer: (ctx) {
                return _buildCell(ctx, greyColor, TextAlign.right);
              },
            ),
            'priceAmplitude': TrinaCell(
              value: "${share.priceAmplitude.toStringAsFixed(2)}%",
              renderer: (ctx) {
                return _buildCell(ctx, greyColor, TextAlign.right);
              },
            ),
            'qrr': TrinaCell(
              value: share.qrr.toStringAsFixed(2),
              renderer: (ctx) {
                return _buildCell(ctx, greyColor, TextAlign.right);
              },
            ),
            'industryName': TrinaCell(value: share.industryName),
            "province": TrinaCell(value: share.province),
          },
        ),
      );
    }
    return newRows;
  }
}
