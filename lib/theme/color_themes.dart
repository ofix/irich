// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/ui/theme/color_theme.dart
// Purpose:     color theme
// Author:      songhuabiao
// Created:     2025-05-22 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';

final lightColorScheme = ColorScheme.light(
  primary: Colors.blue.shade800,
  secondary: Colors.blue.shade600,
  surface: Colors.white,
  error: Colors.red.shade400,
);

final darkColorScheme = ColorScheme.dark(
  primary: Colors.blue.shade300,
  secondary: Colors.blue.shade200,
  surface: const Color.fromARGB(255, 24, 24, 24),
  error: Colors.red.shade300,
);
