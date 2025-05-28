// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/router/router_provider.dart
// Purpose:     router provider
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:irich/router/app_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return appRouter;
});
