// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/rich_widgets/rich_widget_quote.dart
// Purpose:     quote rich widget
// Author:      songhuabiao
// Created:     2025-07-02 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irich/components/rich_widgets/rich_widget.dart';
import 'package:irich/components/progress_popup.dart';
import 'package:irich/components/trina_column_type_stock.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/utils/date_time.dart';
import 'package:trina_grid/trina_grid.dart';

// 市场行情列表控件
class RichWidgetQuote extends RichWidget {
  const RichWidgetQuote({super.key, required super.panelId, super.groupId = 0});
  @override
  ConsumerState<RichWidgetQuote> createState() => _RichWidgetQuoteState();
}

class _RichWidgetQuoteState extends ConsumerState<RichWidgetQuote> with WidgetsBindingObserver {
  late List<TrinaRow> rows; // 股票所有行
  late List<TrinaColumn> cols; // 股票所有列
  late List<Share> shares; // 股票
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
    return Container(
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
                      // ref.read(currentShareCodeProvider.notifier).select(shareCode);
                      context.push('/share');
                    }
                  },
                  mode: TrinaGridMode.readOnly,
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
        TrinaColumnTypeStock(cellType: CellType.price),
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
          Color greyColor = const Color.fromARGB(255, 249, 240, 240);
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
            return _buildPriceCell(text, isUp, columnType.cellType, textAlign);
          } else if (columnType.cellType == CellType.pricePercent) {
            return _buildPriceCell(text, isUp, columnType.cellType, textAlign);
          } else if (columnType.cellType == CellType.amount) {
            return _buildCell(text, greyColor, columnType.cellType, textAlign);
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
      return _buildCell(text, Colors.red, cellType, TextAlign.right);
    } else {
      return _buildCell(text, Colors.green, cellType, TextAlign.right);
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
