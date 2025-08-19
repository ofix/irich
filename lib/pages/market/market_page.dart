// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/ui/market_page.dart
// Purpose:     market page
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irich/components/desktop_layout.dart';
import 'package:irich/components/progress_popup.dart';
import 'package:irich/components/trina_column_type_stock.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/state_quote.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/utils/date_time.dart';
import 'package:trina_grid/trina_grid.dart';

class MarketPage extends ConsumerStatefulWidget {
  final String title;
  const MarketPage({super.key, required this.title});

  @override
  ConsumerState<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends ConsumerState<MarketPage> with WidgetsBindingObserver {
  late List<TrinaRow> rows;
  late List<TrinaColumn> cols;
  late List<Share> shares;

  late bool startRefresh; // 停止行情数据刷新的标志位
  Color? backgroundColor;

  late TrinaGridStateManager stateManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startRefresh = false;
    rows = [];
    cols = [];
    shares = [];
    _load();
  }

  @override
  void dispose() {
    startRefresh = false;
    WidgetsBinding.instance.removeObserver(this);
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
                        gridBackgroundColor: Color.fromARGB(255, 24, 24, 24),
                        enableColumnBorderVertical: true,
                        activatedBorderColor: Colors.transparent,
                        inactivatedBorderColor: const Color.fromARGB(255, 39, 38, 38),
                        rowColor: Color.fromARGB(255, 24, 24, 24),
                        activatedColor: Color(0xff284468),
                        borderColor: const Color.fromARGB(255, 39, 38, 38),
                        cellCheckedColor: Colors.transparent,
                        cellActiveColor: Colors.transparent,
                        columnTextStyle: TextStyle(color: Color(0xFFFFFFFF)),
                        cellTextStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                        rowHeight: 28,
                      ),
                    ),
                    columns: cols,
                    rows: rows,
                    onLoaded: (TrinaGridOnLoadedEvent event) {
                      stateManager = event.stateManager;
                    },
                    onRowDoubleTap: (TrinaGridOnRowDoubleTapEvent event) {
                      String shareCode = (event.row.cells['code']?.value) as String;
                      if (shareCode.isNotEmpty) {
                        ref.read(currentShareCodeProvider.notifier).select(shareCode);
                        context.push('/share');
                      }
                    },
                    mode: TrinaGridMode.readOnly,
                  ),
                ),
      ),
    );
  }

  Future<void> _load() async {
    bool bShowPopup = false;
    // 检查行业/概念/地域板块数据本地文件是否存在
    final isReady = await StoreQuote.isQuoteExtraDataReady();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isReady) {
        // 不存在就显示弹窗，并显示进度条信息
        showProgressPopup(context, StoreQuote.progressStream);
        bShowPopup = true;
      }
      backgroundColor = Theme.of(context).primaryColor;
    });
    // 异步加载行情数据,初始加载还要额外加载概念/地域/行业映射数据
    await StoreQuote.load();
    shares = StoreQuote.shares;
    // 默认按股票涨幅倒序排列显示
    shares.sort((a, b) => b.changeRate.compareTo(a.changeRate));
    rows = _buildRows(shares);
    cols = _buildColumns();
    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (bShowPopup) {
        hideProgressPopup(context);
      }
    });
  }

  // 监听应用生命周期
  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   setState(() {
  //     startRefresh = state == AppLifecycleState.resumed; // 仅在前台时刷新
  //   });
  //   if (startRefresh) refreshQuote(); // 恢复刷新
  // }

  // 定时加载行情数据
  Future<void> refreshQuote() async {
    int delaySeconds = Random().nextInt(5) + 5;
    await Future.delayed(Duration(seconds: delaySeconds));
    final random = Random();
    while (startRefresh) {
      // 只要标志位为 true，就继续循环
      await StoreQuote.loadQuote();
      final currTime = now('yyyy-MM-dd HH:mm:ss');
      debugPrint("[$currTime] 刷新行情数据");
      shares = StoreQuote.shares;
      // 默认按股票涨幅倒序排列显示
      shares.sort((a, b) => b.changeRate.compareTo(a.changeRate));
      rows = _buildRows(shares);
      stateManager.removeAllRows();
      stateManager.appendRows(rows);
      setState(() {});
      int delaySeconds = 5 + random.nextInt(6); // 随机延迟 5~10 秒
      await Future.delayed(Duration(seconds: delaySeconds));
    }
    debugPrint("停止刷新行情数据！");
  }

  // 构建表格标题栏
  List<TrinaColumn> _buildColumns() {
    final fields = [
      ['', 'id', 64, TrinaColumnTextAlign.right, TrinaColumnTypeStock(cellType: CellType.number)],
      [
        '代码',
        'code',
        100,
        TrinaColumnTextAlign.right,
        TrinaColumnTypeStock(cellType: CellType.text),
      ],
      ['名称', 'name', 100, TrinaColumnTextAlign.left, TrinaColumnTypeStock(cellType: CellType.text)],
      [
        '涨幅%',
        'changeRate',
        100,
        TrinaColumnTextAlign.right,
        TrinaColumnTypeStock(cellType: CellType.pricePercent),
      ],
      [
        '现价',
        'priceNow',
        100,
        TrinaColumnTextAlign.right,
        TrinaColumnTypeStock(cellType: CellType.price),
      ],
      [
        '昨收',
        'priceYesterdayClose',
        100,
        TrinaColumnTextAlign.right,
        TrinaColumnTypeStock(cellType: CellType.priceYesterdayClose),
      ],
      [
        '今开',
        'priceOpen',
        100,
        TrinaColumnTextAlign.right,
        TrinaColumnTypeStock(cellType: CellType.price),
      ],
      [
        '最高',
        'priceMax',
        100,
        TrinaColumnTextAlign.right,
        TrinaColumnTypeStock(cellType: CellType.price),
      ],
      [
        '最低',
        'priceMin',
        100,
        TrinaColumnTextAlign.right,
        TrinaColumnTypeStock(cellType: CellType.price),
      ],
      [
        '成交量',
        'volume',
        100,
        TrinaColumnTextAlign.right,
        TrinaColumnTypeStock(cellType: CellType.volume),
      ],
      [
        '成交额',
        'amount',
        100,
        TrinaColumnTextAlign.right,
        TrinaColumnTypeStock(cellType: CellType.amount),
      ],
      [
        '换手',
        'turnoverRate',
        100,
        TrinaColumnTextAlign.right,
        TrinaColumnTypeStock(cellType: CellType.pricePercent),
      ],
      [
        '振幅',
        'priceAmplitude',
        100,
        TrinaColumnTextAlign.right,
        TrinaColumnTypeStock(cellType: CellType.pricePercent),
      ],
      [
        '量比',
        'qrr',
        100,
        TrinaColumnTextAlign.right,
        TrinaColumnTypeStock(cellType: CellType.price),
      ],
      [
        '行业',
        'industryName',
        100,
        TrinaColumnTextAlign.left,
        TrinaColumnTypeStock(cellType: CellType.text),
      ],
      [
        '省份',
        'province',
        100,
        TrinaColumnTextAlign.left,
        TrinaColumnTypeStock(cellType: CellType.text),
      ],
    ];
    Color greyColor = const Color.fromARGB(255, 249, 240, 240);
    return List.generate(fields.length, (index) {
      final field = fields[index];
      return TrinaColumn(
        title: field[0] as String,
        field: field[1] as String,
        type: field[4] as TrinaColumnType,
        width: (field[2] as int).toDouble(),
        readOnly: true,
        titleTextAlign: field[3] as TrinaColumnTextAlign,
        enableContextMenu: false,
        renderer: (TrinaColumnRendererContext ctx) {
          // 获取列的类型
          final columnType = ctx.column.type as TrinaColumnTypeStock;
          final isUp = ctx.row.cells['changeRate']!.value > 0;
          String text = columnType.applyFormat(ctx.cell.value);
          TextAlign textAlign =
              ctx.column.titleTextAlign == TrinaColumnTextAlign.left
                  ? TextAlign.left
                  : ctx.column.titleTextAlign == TrinaColumnTextAlign.right
                  ? TextAlign.right
                  : TextAlign.center;
          if (columnType.cellType == CellType.price) {
            if (ctx.column.field == 'qrr') {
              return _buildCell(text, greyColor, columnType.cellType, textAlign);
            }
            if (ctx.cell.value > ctx.row.cells['priceYesterdayClose']!.value) {
              return _buildPriceCell(text, true, columnType.cellType, textAlign);
            } else if (ctx.cell.value == ctx.row.cells['priceYesterdayClose']!.value) {
              return _buildCell(text, greyColor, columnType.cellType, textAlign);
            } else {
              return _buildPriceCell(text, false, columnType.cellType, textAlign);
            }
          } else if (columnType.cellType == CellType.pricePercent) {
            if (ctx.column.field == 'turnoverRate') {
              // 换手率显示分3个等级，10%，20%，30%
              Color levelColor = greyColor;
              if (ctx.cell.value > 30) {
                levelColor = Color.fromARGB(255, 253, 3, 207);
              } else if (ctx.cell.value > 20) {
                levelColor = Color.fromARGB(255, 240, 47, 49);
              } else if (ctx.cell.value > 10) {
                levelColor = Color.fromARGB(255, 253, 207, 2);
              }
              return _buildCell(text, levelColor, columnType.cellType, textAlign);
            } else if (ctx.column.field == 'priceAmplitude') {
              return _buildCell(text, greyColor, columnType.cellType, textAlign);
            }
            return _buildPriceCell(text, isUp, columnType.cellType, textAlign);
          } else if (columnType.cellType == CellType.amount) {
            Color levelColor = greyColor; // 10亿金额凸出显示
            if (ctx.cell.value >= 1000000000) {
              levelColor = Color.fromARGB(255, 5, 249, 224);
            }
            return _buildCell(text, levelColor, columnType.cellType, textAlign);
          } else if (columnType.cellType == CellType.volume) {
            return _buildCell(text, greyColor, columnType.cellType, textAlign);
          } else if (columnType.cellType == CellType.text) {
            return _buildCell(text, greyColor, columnType.cellType, textAlign);
          }
          return _buildCell(text, greyColor, columnType.cellType, textAlign);
        },
      );
    });
  }

  // 构建单元格
  Widget _buildCell(String text, Color clr, CellType cellType, TextAlign textAlign) {
    return Text(text, style: TextStyle(color: clr), textAlign: textAlign);
  }

  Widget _buildPriceCell(String text, bool isUp, CellType cellType, TextAlign textAlign) {
    if (isUp) {
      return _buildCell(text, const Color.fromARGB(255, 240, 47, 49), cellType, TextAlign.right);
    } else {
      return _buildCell(text, const Color.fromARGB(255, 33, 211, 39), cellType, TextAlign.right);
    }
  }

  // 构建表格行
  List<TrinaRow> _buildRows(List<Share> shares) {
    List<TrinaRow> newRows = [];
    int i = 0;
    for (final share in shares) {
      i++;
      newRows.add(
        TrinaRow(
          cells: {
            'id': TrinaCell(
              value: i,
              renderer: (TrinaCellRendererContext ctx) {
                return Text(
                  (ctx.rowIdx + 1).toString(),
                  style: TextStyle(color: Color.fromARGB(255, 249, 240, 240)),
                  textAlign: TextAlign.right,
                );
              },
            ),
            'code': TrinaCell(value: share.code),
            'name': TrinaCell(value: share.name),
            'changeRate': TrinaCell(value: share.changeRate),
            'priceNow': TrinaCell(value: share.priceNow),
            'priceYesterdayClose': TrinaCell(value: share.priceYesterdayClose),
            'priceOpen': TrinaCell(value: share.priceOpen),
            'priceMax': TrinaCell(value: share.priceMax),
            'priceMin': TrinaCell(value: share.priceMin),
            'amount': TrinaCell(value: share.amount),
            'volume': TrinaCell(value: share.volume),
            'turnoverRate': TrinaCell(value: share.turnoverRate),
            'priceAmplitude': TrinaCell(value: share.priceAmplitude),
            'qrr': TrinaCell(value: share.qrr),
            'industryName': TrinaCell(value: share.industryName),
            "province": TrinaCell(value: share.province),
          },
        ),
      );
    }
    return newRows;
  }
}
