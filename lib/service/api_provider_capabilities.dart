import 'package:irich/service/api_provider.dart';
import 'package:irich/service/api_provider_baidu.dart';
import 'package:irich/service/api_provider_eastmoney.dart';
import 'package:irich/service/api_provider_hexun.dart';

enum EnumApiProvider {
  eastMoney, // 东方财富
  heXun, // 和讯网
  baiduFinance, // 百度财经
}

enum EnumApiType {
  quote, // 大A股票实时行情
  sideMenu, // 侧边栏数据
  industry, // 行业分类数据
  concept, // 概念分类数据
  province, // 省份分类数据
  minuteKline, // 分时K线
  dayKline, // 日K线
  fiveDayKline, // 5日K线
}

class ApiProviderCapabilities {
  final Map<EnumApiType, List<EnumApiProvider>> _capabilities = {
    EnumApiType.quote: [EnumApiProvider.heXun],
    EnumApiType.sideMenu: [EnumApiProvider.eastMoney],
    EnumApiType.industry: [EnumApiProvider.eastMoney],
    EnumApiType.concept: [EnumApiProvider.eastMoney],
    EnumApiType.province: [EnumApiProvider.eastMoney],
    EnumApiType.minuteKline: [
      EnumApiProvider.eastMoney,
      EnumApiProvider.baiduFinance,
    ],
    EnumApiType.dayKline: [
      EnumApiProvider.eastMoney,
      EnumApiProvider.baiduFinance,
    ],
    EnumApiType.fiveDayKline: [
      EnumApiProvider.eastMoney,
      EnumApiProvider.baiduFinance,
    ],
  };

  ApiProviderCapabilities();

  // 获取支持的API类型
  List<EnumApiProvider> getProviders(EnumApiType apiType) {
    return _capabilities[apiType] ?? [];
  }

  // 获取所有支持的API类型
  List<EnumApiType> getAllEnumApiTypes() {
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
    }
  }
}
