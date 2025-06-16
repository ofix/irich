// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/kline_ctrl/kline_ema_curve_buttons.dart
// Purpose:     kline ema curve buttons
// Author:      songhuabiao
// Created:     2025-06-16 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/components/kline_ctrl/kline_chart_state.dart';
import 'package:irich/components/rich_checkbox_button_group.dart';
import 'package:irich/settings/ema_curve_setting.dart';
import 'package:irich/store/provider_kline_ctrl.dart';

class KlineEmaCurveButtons extends ConsumerStatefulWidget {
  const KlineEmaCurveButtons({super.key});
  @override
  ConsumerState<KlineEmaCurveButtons> createState() => _KlineEmaCurveButtonState();
}

class _KlineEmaCurveButtonState extends ConsumerState<KlineEmaCurveButtons> {
  // EMA日K线
  int emaCurveChanged = 0;
  @override
  Widget build(BuildContext context) {
    final emaPrices = ref.watch(emaCurveProvider);
    final state = ref.read(klineCtrlProvider);
    if (emaPrices.isEmpty) {
      return Container(
        width: 800,
        height: KlineCtrlLayout.titleBarHeight,
        color: const Color.fromARGB(255, 24, 24, 24),
      );
    }
    return Container(
      width: 800,
      height: KlineCtrlLayout.titleBarHeight,
      color: const Color.fromARGB(255, 24, 24, 24 /*28, 29, 33*/),
      child: _buildEmaCurveButtons(context, state.emaCurveSettings, emaPrices),
    );
  }

  // 绘制EMA曲线按钮组
  Widget _buildEmaCurveButtons(
    BuildContext context,
    List<EmaCurveSetting> emaCurveSettings,
    Map<int, double> emaPrices,
  ) {
    Map<String, CheckBoxOption> options = {};
    for (final emaCurveSetting in emaCurveSettings) {
      String key =
          'EMA${emaCurveSetting.period}: ${emaPrices[emaCurveSetting.period]!.toStringAsFixed(2)}';
      options[key] = CheckBoxOption(
        selectedColor: emaCurveSetting.color,
        selected: emaCurveSetting.visible,
      );
    }
    return RichCheckboxButtonGroup(
      options: options,
      height: KlineCtrlLayout.titleBarHeight,
      onChanged: (key, option, allOptions) {
        final ema = key.split(':');
        int period = int.parse(ema[0].substring(3));
        ref.read(klineCtrlProvider.notifier).toggleEmaCurve(period);
        emaCurveChanged++;
      },
    );
  }
}
