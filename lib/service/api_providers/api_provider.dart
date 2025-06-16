// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/api_providers/api_provider.dart
// Purpose:     api provider base class
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:charset/charset.dart';
import 'package:flutter/material.dart';
import 'package:irich/service/api_provider_capabilities.dart';
import 'package:http/http.dart' as http;
import 'package:irich/service/request_log.dart';

class ApiResult {
  final int statusCode; // HTTPS 响应状态码
  final String response; // HTTPS 响应数据
  final String url; // 请求URL
  final int responseBytes; // HTTPS 响应数据包大小
  DateTime? requestTime; // 请求开始时间
  DateTime? responseTime; // 请求结束时间

  ApiResult({
    required this.url,
    required this.statusCode,
    required this.response,
    required this.responseBytes,
    this.requestTime,
    this.responseTime,
  }) : assert(statusCode >= 100 && statusCode < 600, 'Invalid HTTP status code'),
       assert(responseBytes >= 0, 'Response bytes cannot be negative');

  ApiResult copyWith({
    int? statusCode,
    String? response,
    String? url,
    int? responseBytes,
    DateTime? requestTime,
    DateTime? responseTime,
  }) {
    return ApiResult(
      statusCode: statusCode ?? this.statusCode,
      response: response ?? this.response,
      url: url ?? this.url,
      responseBytes: responseBytes ?? this.responseBytes,
      requestTime: requestTime ?? this.requestTime,
      responseTime: responseTime ?? this.responseTime,
    );
  }

  /// 计算请求耗时（毫秒）
  int get durationMs {
    if (requestTime == null || responseTime == null) return -1;
    return responseTime!.difference(requestTime!).inMilliseconds;
  }

  /// 检查请求是否成功（状态码2xx）
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
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
      final requestTime = DateTime.now();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15',
        },
      );
      final responseTime = DateTime.now();
      int size = getResponseBytes(response);
      return ApiResult(
        url: url,
        statusCode: response.statusCode,
        response: response.body,
        responseBytes: size,
        requestTime: requestTime,
        responseTime: responseTime,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 返回原始的字符串
  Future<ApiResult> getRawJson(String url) async {
    try {
      final requestTime = DateTime.now();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15',
        },
      );
      final responseTime = DateTime.now();
      int size = getResponseBytes(response);
      return ApiResult(
        url: url,
        statusCode: response.statusCode,
        response: response.body,
        responseBytes: size,
        requestTime: requestTime,
        responseTime: responseTime,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  int getResponseBytes(http.Response response) {
    final contentLength = response.headers['content-length'];
    int size = 0;
    if (contentLength != null) {
      size = int.parse(contentLength);
    } else {
      size = response.bodyBytes.length;
    }
    return size;
  }

  Future<ApiResult> getGbkHtml(String url) async {
    try {
      final requestTime = DateTime.now();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15',
        },
      );
      final responseTime = DateTime.now();
      final gbkBytes = response.bodyBytes; // 将 GBK 字节流转换为 UTF-8 字符串
      final data = gbk.decode(gbkBytes); // 使用 charset 库解码
      int size = getResponseBytes(response);
      return ApiResult(
        url: url,
        statusCode: response.statusCode,
        response: data,
        responseBytes: size,
        requestTime: requestTime,
        responseTime: responseTime,
      );
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }
}
