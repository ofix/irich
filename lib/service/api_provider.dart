import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:irich/service/api_provider_capabilities.dart';
import 'package:http/http.dart' as http;

abstract class ApiProvider {
  EnumApiProvider get provider;
  // 根据请求类型获取接口数据
  Future<dynamic> doRequest(ProviderApiType apiType, Map<String, dynamic> params);
  // 根据请求类型解析响应数据
  dynamic parseResponse(ProviderApiType apiType, dynamic response);

  Future<dynamic> getJson(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception("request $url failed");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 返回原始的字符串
  Future<String> getRawJson(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15',
        },
      );
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception("request $url failed");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<String> getHtml(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15',
        },
      );
      return response.body;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
}
