import 'package:irich/service/api_provider_capabilities.dart';

abstract class ApiProvider {
  EnumApiProvider get name;
  // 根据请求类型获取接口数据
  Future<dynamic> doRequest(
    EnumApiType enumApiType,
    Map<String, dynamic> params,
  );
  // 根据请求类型解析响应数据
  void parseResponse(EnumApiType enumApiType, dynamic response);
}
