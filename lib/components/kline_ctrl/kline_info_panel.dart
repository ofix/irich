// /////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/kline_ctrl/kline_info_panel.dart
// Purpose:     irich kline info panel
// Author:      songhuabiao
// Created:     2025-06-03 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// /////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/store/provider_kline_ctrl.dart';
import 'package:irich/utils/helper.dart';

class KlineInfoPanel extends ConsumerStatefulWidget {
  const KlineInfoPanel({super.key});

  @override
  ConsumerState<KlineInfoPanel> createState() => _KlineInfoPanelState();
}

class _KlineInfoPanelState extends ConsumerState<KlineInfoPanel> {
  Offset _position = const Offset(20, 70);
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final klineInfo = ref.watch(klineInfoCtrlProvider);
    final kline = klineInfo.kline;
    final yesterdayPriceClose = klineInfo.yesterdayPriceClose;
    final visible = klineInfo.visible;
    if (!visible) {
      return const SizedBox.shrink(); // 或者 return const Offstage();
    }

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
              width: 146,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('日期', kline.day, Colors.grey),
                  _buildInfoRow(
                    '涨幅',
                    '${(kline.changeRate).toStringAsFixed(2)}%',
                    kline.changeRate > 0
                        ? Colors.red
                        : (kline.changeRate < 0 ? Colors.green : Colors.grey),
                  ),
                  _buildInfoRow(
                    '开盘',
                    kline.priceOpen.toStringAsFixed(2),
                    _getPriceColor(kline.priceOpen, yesterdayPriceClose),
                  ),
                  _buildInfoRow(
                    '收盘',
                    kline.priceClose.toStringAsFixed(2),
                    _getPriceColor(kline.priceClose, yesterdayPriceClose),
                  ),
                  _buildInfoRow(
                    '最高',
                    kline.priceMax.toStringAsFixed(2),
                    _getPriceColor(kline.priceMax, yesterdayPriceClose),
                  ),
                  _buildInfoRow(
                    '最低',
                    kline.priceClose.toStringAsFixed(2),
                    _getPriceColor(kline.priceMin, yesterdayPriceClose),
                  ),
                  _buildInfoRow('成交量', Helper.richUnit(kline.volume.toDouble()), Colors.grey),
                  _buildInfoRow("成交额", Helper.richUnit(kline.amount), Colors.grey),
                  _buildInfoRow('换手率', '${(kline.turnoverRate).toStringAsFixed(2)}%', Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriceColor(double value, double yesterdayPriceClose) {
    if (value > yesterdayPriceClose) {
      return Colors.red; // 涨
    } else if (value < yesterdayPriceClose) {
      return Colors.green; // 跌
    } else {
      return Colors.grey; // 平
    }
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
