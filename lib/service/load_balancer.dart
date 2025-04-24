////////////////////////////////////////////////////////////////////////////////
// Name:        irich/spider/spider_router.dart
// Purpose:     爬虫路由器,以负载均衡的方式抓取财经数据
// Author:      songhuabiao
// Created:     2025-04-16 10:58
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
///////////////////////////////////////////////////////////////////////////////
// ignore_for_file: dangling_library_doc_comments

import 'dart:math';

import 'package:irich/service/api_provider.dart';
import 'package:irich/service/api_provider_capabilities.dart';

class LoadBalancer {
  static final ApiProviderCapabilities _providerCapabilities =
      ApiProviderCapabilities(); // 提供商能力
  final _providerWeights = <EnumApiProvider, int>{}; // 供应商权重
  List<ApiProvider> providers = []; // 当前的供应商
  EnumApiType apiType = EnumApiType.quote; //  当前请求的主题

  LoadBalancer();

  // void _initWeights(EnumApiType type) {
  //   List<EnumApiProvider> providers = _providerCapabilities.getProviders(type);
  //   for (var provider in providers) {
  //     _providerWeights[provider] = 1; // 初始化权重为1
  //   }
  // }

  // 根据请求的接口类型动态获取供应商
  ApiProvider _selectProvider(EnumApiType apiType) {
    List<EnumApiProvider> enumProviders = _providerCapabilities.getProviders(
      apiType,
    );
    if (enumProviders.isEmpty) throw Exception('No available data provider');

    // 按当前权重随机选择
    final totalWeight = providers.fold(0, (sum, s) => sum + 1);
    var random = Random().nextInt(totalWeight);

    for (final enumProvider in enumProviders) {
      random -= _providerWeights[enumProvider] ?? 1;
      if (random <= 0) {
        return _providerCapabilities.getProviderByEnum(enumProvider);
      }
    }
    return providers.last;
  }

  // 5. 带负载均衡的请求方法
  dynamic request(EnumApiType apiType, Map<String,dynamic> params) async {
    final provider = _selectProvider(apiType);
    try {
      final response = await provider.doRequest(apiType, params);
      return provider.parseResponse(apiType, response);
    } catch (e) {
      rethrow;
    }
  }

}
