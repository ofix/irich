////////////////////////////////////////////////////////////////////////////////
// Name:        irich/spider/spider_router.dart
// Purpose:     爬虫路由器,以负载均衡的方式抓取财经数据
// Author:      songhuabiao
// Created:     2025-04-16 10:58
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
///////////////////////////////////////////////////////////////////////////////
// ignore_for_file: dangling_library_doc_comments

import 'package:irich/service/api_provider.dart';
import 'package:irich/service/api_provider_capabilities.dart';

class LoadBalancer {
  static final ApiProviderCapabilities _providerCapabilities = ApiProviderCapabilities(); // 提供商能力
  Map<EnumApiProvider, int> _providerWeights = {}; // 供应商权重
  late ProviderApiType _curApiType;
  late ApiProvider _curProvider;

  // 加权轮询算法(IWWR)
  final List<EnumApiProvider> _weightRoundRobinProviders = []; // 将加权的供应商列表转换成轮询的供应商列表
  int _weightRoundRobinIndex = 0; // 当前选中的供应商下标

  // 初始化供应商权重
  LoadBalancer(ProviderApiType apiType) {
    _fastWeightRoundRobinInit(apiType);
  }

  // 1.快速加权轮询算法（用空间换取时间）
  // 根据当前爬取的主题初始化对应API接口供应商的权重
  void _fastWeightRoundRobinInit(ProviderApiType apiType) {
    _providerWeights = {
      EnumApiProvider.eastMoney: 4,
      EnumApiProvider.baiduFinance: 3,
      EnumApiProvider.heXun: 1,
    };
    _curApiType = apiType;
    _weightRoundRobinIndex = 0;
    final enumProviders = _providerCapabilities.getProviders(apiType);
    if (enumProviders.length == 1) {
      _weightRoundRobinProviders.add(enumProviders.first); // 只有一个供应商,无需轮询
      return;
    }
    // 有多个供应商，才需要加权轮询
    for (final enumProvider in enumProviders) {
      int weight = _providerWeights[enumProvider]!;
      for (int i = 0; i < weight; i++) {
        _weightRoundRobinProviders.add(enumProvider);
      }
    }
    // 原地随机打乱
    _weightRoundRobinProviders.shuffle();
  }

  // 加权轮询法-获取下一个 API 供应商
  ApiProvider _fastWeightRoundRobinNextApiProvider() {
    if (_weightRoundRobinProviders.length == 1) {
      return _providerCapabilities.getProviderByEnum(_weightRoundRobinProviders.first);
    }
    // 按当前权重随机选择
    if (_weightRoundRobinIndex >= _weightRoundRobinProviders.length) {
      _weightRoundRobinIndex = 0;
    }
    // 获取下一个供应商
    final enumProvider = _weightRoundRobinProviders[_weightRoundRobinIndex++];
    return _providerCapabilities.getProviderByEnum(enumProvider);
  }

  // 根据请求的接口类型动态获取供应商
  ApiProvider _nextApiProvider() {
    return _fastWeightRoundRobinNextApiProvider();
  }

  // 带负载均衡的请求方法
  Future<dynamic> request(Map<String, dynamic> params) async {
    _curProvider = _nextApiProvider();
    try {
      final response = await _curProvider.doRequest(_curApiType, params);
      return _curProvider.parseResponse(_curApiType, response);
    } catch (e) {
      rethrow;
    }
  }

  // 带负载均衡的请求方法
  Future<String> rawRequest(Map<String, dynamic> params) async {
    _curProvider = _nextApiProvider();
    try {
      final response = await _curProvider.doRequest(_curApiType, params);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  ApiProvider get apiProvider => _curProvider;
}
