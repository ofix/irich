// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/api_provider_capabilities.dart
// Purpose:     map api providers and their capabilities
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/service/api_providers/api_provider.dart';
import 'package:irich/service/api_providers/api_provider_baidu.dart';
import 'package:irich/service/api_providers/api_provider_eastmoney.dart';
import 'package:irich/service/api_providers/api_provider_hexun.dart';
import 'package:irich/service/api_providers/api_provider_ifind.dart';
import 'package:irich/service/api_providers/api_provider_sina.dart';

enum EnumApiProvider {
  eastMoney(1), // 东方财富
  heXun(2), // 和讯网
  baiduFinance(3), // 百度财经
  iFind(4), // 同花顺
  sina(5), // 新浪财经
  unknown(255); // 未知供应商

  final int provider;
  const EnumApiProvider(this.provider);

  int get val => provider;
  static EnumApiProvider fromVal(int value) {
    switch (value) {
      case 1:
        return EnumApiProvider.eastMoney;
      case 2:
        return EnumApiProvider.heXun;
      case 3:
        return EnumApiProvider.baiduFinance;
      case 4:
        return EnumApiProvider.iFind;
      case 5:
        return EnumApiProvider.sina;
      case 255:
        return EnumApiProvider.unknown;
      default:
        return EnumApiProvider.unknown;
    }
  }

  String get name {
    switch (this) {
      case EnumApiProvider.eastMoney:
        return 'eastmoney';
      case EnumApiProvider.heXun:
        return 'hexun';
      case EnumApiProvider.baiduFinance:
        return 'baidu_finance';
      case EnumApiProvider.iFind:
        return 'ifind';
      case EnumApiProvider.sina:
        return "sina";
      case EnumApiProvider.unknown:
        return 'unknown';
    }
  }

  String get chineseName {
    switch (this) {
      case EnumApiProvider.eastMoney:
        return '东方财富';
      case EnumApiProvider.heXun:
        return '和讯网';
      case EnumApiProvider.baiduFinance:
        return '百度财经';
      case EnumApiProvider.iFind:
        return '同花顺';
      case EnumApiProvider.sina:
        return "新浪财经";
      case EnumApiProvider.unknown:
        return '未知供应商';
    }
  }
}

enum ProviderApiType {
  quote(1), // 大A股票实时行情
  quoteExtra(2), // 分类板块入口
  industry(3), // 行业分类数据
  concept(4), // 概念分类数据
  province(5), // 省份分类数据
  minuteKline(6), // 分时K线
  dayKline(7), // 日K线
  fiveDayKline(8), // 5日K线
  indexList(9), // 指数列表
  unknown(255); // 未知类型

  final int apiType;
  const ProviderApiType(this.apiType);

  int get val => apiType;
  static ProviderApiType fromVal(int value) {
    switch (value) {
      case 1:
        return ProviderApiType.quote;
      case 2:
        return ProviderApiType.quoteExtra;
      case 3:
        return ProviderApiType.industry;
      case 4:
        return ProviderApiType.concept;
      case 5:
        return ProviderApiType.province;
      case 6:
        return ProviderApiType.minuteKline;
      case 7:
        return ProviderApiType.dayKline;
      case 8:
        return ProviderApiType.fiveDayKline;
      case 9:
        return ProviderApiType.indexList;
      case 255:
        return ProviderApiType.unknown;
      default:
        return ProviderApiType.unknown;
    }
  }

  String get name {
    switch (this) {
      case ProviderApiType.quote:
        return '股票行情';
      case ProviderApiType.quoteExtra:
        return '板块分类';
      case ProviderApiType.industry:
        return '行业板块';
      case ProviderApiType.concept:
        return '概念板块';
      case ProviderApiType.province:
        return '地域板块';
      case ProviderApiType.minuteKline:
        return '分时图';
      case ProviderApiType.dayKline:
        return '日K线';
      case ProviderApiType.fiveDayKline:
        return '五日分时图';
      case ProviderApiType.indexList:
        return "指数行情";
      case ProviderApiType.unknown:
        return '未知';
    }
  }
}

class ApiProviderCapabilities {
  final Map<ProviderApiType, List<EnumApiProvider>> _capabilities = {
    ProviderApiType.quote: [EnumApiProvider.eastMoney],
    ProviderApiType.quoteExtra: [EnumApiProvider.eastMoney],
    ProviderApiType.industry: [EnumApiProvider.eastMoney],
    ProviderApiType.concept: [EnumApiProvider.eastMoney],
    ProviderApiType.province: [EnumApiProvider.eastMoney],
    ProviderApiType.minuteKline: [EnumApiProvider.baiduFinance],
    ProviderApiType.dayKline: [EnumApiProvider.eastMoney, EnumApiProvider.baiduFinance],
    ProviderApiType.fiveDayKline: [EnumApiProvider.baiduFinance],
    ProviderApiType.indexList: [EnumApiProvider.eastMoney],
  };

  ApiProviderCapabilities();

  // 获取支持的API类型
  List<EnumApiProvider> getProviders(ProviderApiType apiType) {
    return _capabilities[apiType] ?? [];
  }

  // 获取所有支持的API类型
  List<ProviderApiType> getAllProviderApiTypes() {
    return _capabilities.keys.toList();
  }

  // 根据供应商枚举类型，返回对应供应商的实例
  ApiProvider getProviderByEnum(EnumApiProvider provider) {
    switch (provider) {
      case EnumApiProvider.eastMoney:
        return ApiProviderEastMoney();
      case EnumApiProvider.heXun:
        return ApiProviderHexun();
      case EnumApiProvider.baiduFinance:
        return ApiProviderBaidu();
      case EnumApiProvider.iFind:
        return ApiProviderIfind();
      case EnumApiProvider.sina:
        return ApiProviderSina();
      case EnumApiProvider.unknown:
        throw ArgumentError('Unknown API provider: $provider');
    }
  }
}
