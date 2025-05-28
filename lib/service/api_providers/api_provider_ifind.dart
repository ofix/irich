// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/api_providers/api_provider_ifind.dart
// Purpose:     ifind api provider
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:charset/charset.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:irich/service/api_providers/api_provider.dart';
import 'package:irich/service/api_provider_capabilities.dart';
import 'package:irich/service/request_log.dart';

// 同花顺数据中心
class ApiProviderIfind extends ApiProvider {
  @override
  final provider = EnumApiProvider.iFind;

  @override
  Future<dynamic> doRequest(
    ProviderApiType apiType,
    Map<String, dynamic> params, [
    void Function(RequestLog requestLog)? onPagerProgress,
  ]) async {
    switch (apiType) {
      case ProviderApiType.quoteExtra:
        return fetchQuoteExtra(params);
      case ProviderApiType.industry:
      case ProviderApiType.concept:
      case ProviderApiType.province:
        return fetchBk(params, apiType, onPagerProgress); // 地域/行业/概念板块数据
      default:
        throw UnimplementedError('Unsupported API type: $ProviderApiType');
    }
  }

  // 根据请求类型解析响应数据
  @override
  dynamic parseResponse(ProviderApiType apiType, dynamic response) {
    switch (apiType) {
      case ProviderApiType.quoteExtra:
        return parseQuoteExtra(response); // 侧边栏数据
      case ProviderApiType.industry:
      case ProviderApiType.concept:
      case ProviderApiType.province:
        return parseBk(response); // 地域/行业/概念板块数据
      default:
        throw UnimplementedError('Unsupported API type: $ProviderApiType');
    }
  }

  // 获取侧边栏数据
  Future<dynamic> fetchQuoteExtra(Map<String, dynamic> params) async {
    final responses = <String>[];
    final bkList = ["dy", "thshy", "gn"]; // 地域｜概念｜同花顺行业
    try {
      for (final bk in bkList) {
        final result = await getGbkHtml("https://q.10jqka.com.cn/$bk/"); // 地域板块
        responses.add(result.response);
      }
      return responses;
    } catch (e) {
      rethrow;
    }
  }

  List<List<Map<String, dynamic>>> parseQuoteExtra(List<String> responses) {
    final List<List<Map<String, dynamic>>> result = [];
    final bkList = ["dy", "thshy", "gn"]; // 地域｜概念｜同花顺行业
    // 解析Html数据
    for (int i = 0; i < responses.length; i++) {
      final doc = parse(responses[i]);
      final elements = doc.querySelectorAll('.category .cate_items a');
      final bk = <Map<String, dynamic>>[];
      for (final ele in elements) {
        String? url = ele.attributes['href'];
        String? code = _getBkCode(url!);
        String pinyin = ""; // ChinesePinYin.getFirstLetters(ele.text)[0];
        debugPrint(
          "url: $url, name: ${ele.text}, code:$code, category:${bkList[i]}, pinyin;$pinyin ",
        );
        bk.add({"Url": url, "Name": ele.text, "Code": code, "Category": bkList[i], pinyin: pinyin});
      }
      result.add(bk);
    }
    return result;
  }

  // 构造同花顺板块分页异步请求URL
  /// [pageIndex] 分页序号
  /// [bkCategory] 板块分类缩写，["dy", "thshy", "gn"] 地域｜概念｜同花顺行业
  /// [hiddenParam] 分页隐藏参数
  /// [bkCode] 板块代号
  String _buildBkPageUrl(
    int pageIndex,
    String bkCategory,
    String baseUrl,
    String hiddenParam,
    String bkCode,
  ) {
    return "https://q.10jqka.com.cn/$bkCategory/detail/field/199112/order/desc/page/$pageIndex/ajax/1/code/$bkCode";
  }

  String _getBkCode(String url) {
    // 找到最后一个 '/' 的位置
    int lastSlashIndex = url.lastIndexOf('/');
    int secondLastSlashIndex = url.lastIndexOf('/', lastSlashIndex - 1);
    // 截取数字部分
    String number = url.substring(secondLastSlashIndex + 1, lastSlashIndex);
    return number;
  }

  Future<dynamic> fetchBk(
    Map<String, dynamic> params,
    ProviderApiType apiType, [
    void Function(RequestLog requestLog)? onPagerProgress,
  ]) async {
    final html = await getGbkHtml(params['Url']);
    debugPrint("请求分页 ${params['Url']}");
    final doc = parse(html);
    List<String> pageUrls = [];
    List<String> shares = [];
    // 第一页数据
    final pageOneElements = doc.querySelectorAll(".m-pager-box tbody tr a");
    for (int i = 0; i < pageOneElements.length; i += 2) {
      shares.add(pageOneElements[i].text);
    }
    // 最大页码
    final pages = doc.querySelectorAll(".body .m-pager .changePage");
    if (pages.isEmpty) {
      debugPrint("${params['Name']}: ${shares.toString()}");
      return shares; // 没有分页,比如贵州省
    }
    final pageSizeElement = pages[pages.length - 1];
    // 请求路径
    final hiddenParamBaseUrl = doc.querySelector(".m-pager-box #baseUrl");
    // 请求隐藏参数
    final hiddenParamQuery = doc.querySelector(".m-pager-box #requestQuery");
    int pageSize = int.parse(pageSizeElement.attributes['page']!);
    String? hiddenParam = hiddenParamQuery?.attributes['value'];
    String? baseUrl = hiddenParamBaseUrl?.attributes['value'];
    debugPrint("pageSize: $pageSize, baseUrl:$baseUrl, hiddenParam: $hiddenParam");
    for (int i = 2; i <= pageSize; i++) {
      String pageUrl = _buildBkPageUrl(
        i,
        params['Category'],
        baseUrl!,
        hiddenParam!,
        params['Code'],
      );
      pageUrls.add(pageUrl);
    }
    String cookie = _genCookie();
    // 继续请求剩下的分页数据
    for (int i = 0; i < pageUrls.length; i++) {
      DateTime requestTime = DateTime.now();
      final htmlPage = await _getGbkHtml(pageUrls[i], cookie);
      DateTime responseTime = DateTime.now();
      debugPrint("请求分页${params['name']} => ${pageUrls[i]}");
      debugPrint("响应数据大小: ${htmlPage.response.length}");
      final docPage = parse(htmlPage);
      // 分页数据
      final pageElements = docPage.querySelectorAll(".m-pager-table tbody tr a");
      debugPrint("size: ${pageElements.length}");
      for (int i = 0; i < pageElements.length; i += 2) {
        shares.add(pageElements[i].text);
      }

      final requestLog = RequestLog(
        taskId: params['TaskId'],
        providerId: provider,
        apiType: apiType,
        responseBytes: htmlPage.response.length,
        requestTime: requestTime,
        responseTime: responseTime,
        url: pageUrls[i],
        statusCode: htmlPage.statusCode,
        duration: responseTime.difference(requestTime).inMilliseconds,
      );
      onPagerProgress?.call(requestLog);

      // 随机延时
      final random = Random();
      int delaySeconds = 2 + random.nextInt(3); // 随机 1~2 秒
      await Future.delayed(Duration(seconds: delaySeconds));
    }
    debugPrint("${params['Name']}: ${shares.toString()}");
    return shares;
  }

  String _genCookie() {
    // 创建一个 Cookie 列表
    List<Cookie> cookies = [
      Cookie('escapename', 'mo_385333244')..path = '/',
      Cookie('ticket', '25ff6603695fce7724700deeee4ec32b')..path = '/',
      Cookie('ttype', 'WEB')..path = '/',
      Cookie('u_did', 'BCD46556DD6347FC897B0966104B9858')..path = '/',
      Cookie(
        'u_dpass',
        'zELfEXADsfBmbTguaYgNEsg%2FGel1PDOq8yoq8xTJ5FIRAPdOVVSaAoX7HxtuaoM%2BHi80LrSsTFH9a%2B6rtRvqGg%3D%3D',
      )..path = '/',
      Cookie('u_name', 'mo_385333244')..path = '/',
      Cookie('u_ttype', 'WEB')..path = '/',
      Cookie('u_ukey', 'A10702B8689642C6BE607730E11E6E4A')..path = '/',
      Cookie('u_uver', '1.0.0')..path = '/',
      Cookie(
        'user',
        'MDptb18zODUzMzMyNDQ6Ok5vbmU6NTAwOjM5NTMzMzI0NDo3LDExMTExMTExMTExLDQwOzQ0LDExLDQwOzYsMSw0MDs1LDEsNDA7MSwxMDEsNDA7MiwxLDQwOzMsMSw0MDs1LDEsNDA7OCwwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMSw0MDsxMDIsMSw0MDoyNDo6OjM4NTMzMzI0NDoxNzQ2NTI3ODA0Ojo6MTQ4OTk5ODY2MDo2MDQ4MDA6MDoxNDRjY2Y0MDQwOWUzYWUwYTVmMDc4YjYxM2FlNDQ0YjI6ZGVmYXVsdF80OjE%3D',
      )..path = '/',
      Cookie('user_status', '0')..path = '/',
      Cookie('userid', '385333244')..path = '/',
      Cookie('utk', '04a42e9ef0f5b58e52e5a0f778a713af')..path = '/',
      Cookie('v', 'A_G_7_aBPZmd35GNpcc_iCWMBn-O3mRRD1YJdtMF7grXTB_oGy51IJ-iGTJg')..path = '/',
    ];

    // 设置 Cookie 的公共属性
    for (var cookie in cookies) {
      cookie
        ..domain =
            '.10jqka.com.cn' // 替换为你的域名
        ..httpOnly = true
        ..secure = true
        ..maxAge = 8640000; // 1天有效期（单位：秒）
    }

    return cookies.map((c) => c.toString()).join(', ');
  }

  Future<ApiResult> _getGbkHtml(String url, cookie) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15',
          "Sec-Fetch-Dest": "empty",
          "Sec-Fetch-Mode": "cors",
          "Sec-Fetch-Site": "same-origin",
          "X-Requested-With": "XMLHttpRequest",
          "Cookie": cookie,
        },
      );
      // 将 GBK 字节流转换为 UTF-8 字符串
      int size = getResponseBytes(response);
      if (response.statusCode == 200) {
        final gbkBytes = response.bodyBytes;
        final data = gbk.decode(gbkBytes); // 使用 charset 库解码
        return ApiResult(url, response.statusCode, data, size);
      }
      return ApiResult(url, response.statusCode, response.body, size);
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  // 随机延时

  List<String> parseBk(List<String> responses) {
    final List<String> shareList = [];
    // 解析JSON数据
    for (final response in responses) {
      final result = jsonDecode(response);
      final data = result["data"]['diff'];
      for (final row in data) {
        final String shareCode = row["f12"]; // 股票名称
        shareList.add(shareCode);
      }
    }
    return shareList;
  }
}
