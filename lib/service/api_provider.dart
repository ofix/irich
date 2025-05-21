// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/api_provider.dart
// Purpose:     api provider base class
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:charset/charset.dart';
import 'package:flutter/material.dart';
import 'package:irich/service/api_provider_capabilities.dart';
import 'package:http/http.dart' as http;
import 'package:irich/service/request_log.dart';

class ApiResult {
  final int statusCode;
  final String response;
  final String url;
  ApiResult(this.url, this.statusCode, this.response);
}

abstract class ApiProvider {
  EnumApiProvider get provider;
  // 根据请求类型获取接口数据
  Future<dynamic> doRequest(
    ProviderApiType apiType,
    Map<String, dynamic> params, [
    void Function(RequestLog requestLog)? onPagerProgress,
  ]);
  // 根据请求类型解析响应数据
  dynamic parseResponse(ProviderApiType apiType, dynamic response);

  Future<ApiResult> getJson(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15',
        },
      );
      return ApiResult(url, response.statusCode, response.body);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 返回原始的字符串
  Future<ApiResult> getRawJson(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15',
        },
      );
      return ApiResult(url, response.statusCode, response.body);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<ApiResult> getGbkHtml(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15',
        },
      );
      final gbkBytes = response.bodyBytes; // 将 GBK 字节流转换为 UTF-8 字符串
      final data = gbk.decode(gbkBytes); // 使用 charset 库解码
      return ApiResult(url, response.statusCode, data);
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
}
