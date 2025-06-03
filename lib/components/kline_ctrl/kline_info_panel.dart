// /////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/kline_ctrl/kline_info_panel.dart
// Purpose:     irich kline info panel
// Author:      songhuabiao
// Created:     2025-06-03 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// /////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/utils/helper.dart';

class KlineInfoPanel extends StatefulWidget {
  final double yesterdayPriceClose; // 昨天收盘价
  final UiKline uiKline; // 当前日K线

  const KlineInfoPanel({super.key, required this.yesterdayPriceClose, required this.uiKline});

  @override
  State<KlineInfoPanel> createState() => _KlineInfoPanelState();
}

class _KlineInfoPanelState extends State<KlineInfoPanel> {
  Offset _position = const Offset(20, 20);
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final kline = widget.uiKline;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        onPanEnd: (_) => setState(() => _isDragging = false),
        child: Opacity(
          opacity: _isDragging ? 0.8 : 1.0,
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(4),
            color: Theme.of(context).cardColor,
            child: Container(
              width: 240,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('日期', kline.day, Colors.grey),
                  _buildInfoRow(
                    '涨幅',
                    '${(kline.changeRate * 100).toStringAsFixed(2)}%',
                    kline.changeRate > 0
                        ? Colors.red
                        : (kline.changeRate < 0 ? Colors.green : Colors.grey),
                  ),
                  _buildInfoRow(
                    '开盘',
                    kline.priceOpen.toStringAsFixed(2),
                    _getPriceColor(kline.priceOpen),
                  ),
                  _buildInfoRow(
                    '收盘',
                    kline.priceClose.toStringAsFixed(2),
                    _getPriceColor(kline.priceClose),
                  ),
                  _buildInfoRow(
                    '最高',
                    kline.priceMax.toStringAsFixed(2),
                    _getPriceColor(kline.priceMax),
                  ),
                  _buildInfoRow(
                    '最低',
                    kline.priceClose.toStringAsFixed(2),
                    _getPriceColor(kline.priceMin),
                  ),
                  _buildInfoRow('成交量', Helper.richUnit(kline.volume.toDouble()), Colors.grey),
                  _buildInfoRow("成交额", Helper.richUnit(kline.amount), Colors.grey),
                  _buildInfoRow(
                    '换手率',
                    '${(kline.turnoverRate * 100).toStringAsFixed(2)}%',
                    Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriceColor(double value) {
    if (value > widget.yesterdayPriceClose) {
      return Colors.red; // 涨
    } else if (value < widget.yesterdayPriceClose) {
      return Colors.green; // 跌
    } else {
      return Colors.grey; // 平
    }
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
