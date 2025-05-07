import 'package:irich/service/api_provider.dart';
import 'package:irich/service/api_provider_baidu.dart';
import 'package:irich/service/api_provider_eastmoney.dart';
import 'package:irich/service/api_provider_hexun.dart';
import 'package:irich/service/api_provider_ifind.dart';

enum EnumApiProvider {
  eastMoney, // 东方财富
  heXun, // 和讯网
  baiduFinance, // 百度财经
  iFind, // 同花顺
}

// 为枚举添加扩展方法
extension EnumApiProviderExtension on EnumApiProvider {
  String get name {
    switch (this) {
      case EnumApiProvider.eastMoney:
        return '[东方财富]';
      case EnumApiProvider.heXun:
        return '[和讯网]';
      case EnumApiProvider.baiduFinance:
        return '[百度财经]';
      case EnumApiProvider.iFind:
        return '[同花顺]';
    }
  }
}

enum ProviderApiType {
  quote, // 大A股票实时行情
  quoteExtra, // 分类板块入口
  industry, // 行业分类数据
  concept, // 概念分类数据
  province, // 省份分类数据
  minuteKline, // 分时K线
  dayKline, // 日K线
  fiveDayKline, // 5日K线
}

class ApiProviderCapabilities {
  final Map<ProviderApiType, List<EnumApiProvider>> _capabilities = {
    ProviderApiType.quote: [EnumApiProvider.heXun],
    ProviderApiType.quoteExtra: [EnumApiProvider.eastMoney],
    ProviderApiType.industry: [EnumApiProvider.eastMoney],
    ProviderApiType.concept: [EnumApiProvider.eastMoney],
    ProviderApiType.province: [EnumApiProvider.eastMoney],
    ProviderApiType.minuteKline: [EnumApiProvider.eastMoney, EnumApiProvider.baiduFinance],
    ProviderApiType.dayKline: [EnumApiProvider.eastMoney, EnumApiProvider.baiduFinance],
    ProviderApiType.fiveDayKline: [EnumApiProvider.eastMoney, EnumApiProvider.baiduFinance],
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
    }
  }
}
