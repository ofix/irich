// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/settings/user_preference.dart
// Purpose:     User Preference
// Author:      songhuabiao
// Created:     2025-06-12 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/global/stock.dart';
import 'package:irich/settings/ema_curve_setting.dart';
import 'package:irich/settings/panel_layout_setting.dart';

/// 用户偏好设置
class UserPreference {
  // K线设置
  List<EmaCurveSetting> emaCurveSettings = defaultEmaCurveSettings;
  // 自选股列表
  List<Share> favoriteShareSettings = [];
  // 版面设置
  List<PanelLayoutSetting> panelLayoutSettings = [];
}
