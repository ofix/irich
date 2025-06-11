// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/provider_debug.dart
// Purpose:     riverpod observer for debugging
// Author:      songhuabiao
// Created:     2025-06-11 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RichProviderObserver extends ProviderObserver {
  @override
  void didAddProvider(ProviderBase<Object?> provider, Object? value, ProviderContainer container) {
    debugPrint('Provider $provider was initialized');
  }

  @override
  void didDisposeProvider(ProviderBase<Object?> provider, ProviderContainer container) {
    debugPrint('Provider $provider was disposed');
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    debugPrint('Provider $provider updated');
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    debugPrint('Provider $provider threw $error at $stackTrace');
  }
}
