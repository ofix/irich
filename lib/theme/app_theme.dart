// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/theme/app_theme.dart
// Purpose:     application theme
// Author:      songhuabiao
// Created:     2025-05-22 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:irich/theme/color_themes.dart';
import 'package:irich/theme/stock_colors.dart';

class AppTheme {
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: lightColorScheme.primary,
        foregroundColor: lightColorScheme.onPrimary,
        elevation: 2,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: lightColorScheme.surface),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      extensions: <ThemeExtension<dynamic>>[
        StockColors.light(), // 注入股票颜色
      ],
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.surface,
        foregroundColor: darkColorScheme.onSurface,
        elevation: 2,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: darkColorScheme.surface),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      extensions: <ThemeExtension<dynamic>>[
        StockColors.dark(), // 注入股票颜色
      ],
    );
  }
}
