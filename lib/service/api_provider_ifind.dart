import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:irich/service/api_provider.dart';
import 'package:irich/service/api_provider_capabilities.dart';
import 'package:irich/utils/chinese_pin_yin.dart';

// 同花顺数据中心
class ApiProviderIfind extends ApiProvider {
  @override
  final provider = EnumApiProvider.iFind;

  @override
  Future<dynamic> doRequest(ProviderApiType apiType, Map<String, dynamic> params) async {
    switch (apiType) {
      case ProviderApiType.quoteExtra:
        return fetchQuoteExtra(params);
      case ProviderApiType.industry:
      case ProviderApiType.concept:
      case ProviderApiType.province:
        return fetchBk(params); // 地域/行业/概念板块数据
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
        String html = await getHtml("https://q.10jqka.com.cn/$bk/"); // 地域板块
        responses.add(html);
      }
      return responses;
    } catch (e) {
      rethrow;
    }
  }

  List<List<Map<String, dynamic>>> parseQuoteExtra(List<String> responses) {
    final List<List<Map<String, dynamic>>> result = [];
    // 解析Html数据
    for (final response in responses) {
      final doc = parse(response);
      final elements = doc.querySelectorAll('.category .cate_items a');
      final bk = <Map<String, dynamic>>[];
      for (final ele in elements) {
        String? url = ele.attributes['href'];
        String? code = _getBkCode(url!);
        String pinyin = ChinesePinYin.getFirstLetters(ele.text)[0];
        debugPrint("url: $url, name: ${ele.text}, code:$code, pinyin;$pinyin ");
        bk.add({"url": url, "name": ele.text, "code": code, pinyin: pinyin});
      }
      result.add(bk);
    }
    return result;
  }

  // 构造同花顺板块分页异步请求URL
  /// [pageIndex] 分页序号
  /// [hiddenParam] 分页隐藏参数
  /// [bkCode] 板块代号
  String _buildBkPageUrl(int pageIndex, String baseUrl, String hiddenParam, String bkCode) {
    return "https://q.10jqka.com.cn/gn/detail/field/199112/order/desc/page/$pageIndex/ajax/1/code/$bkCode";
  }

  String _getBkCode(String url) {
    // 找到最后一个 '/' 的位置
    int lastSlashIndex = url.lastIndexOf('/');
    int secondLastSlashIndex = url.lastIndexOf('/', lastSlashIndex - 1);
    // 截取数字部分
    String number = url.substring(secondLastSlashIndex + 1, lastSlashIndex);
    return number;
  }

  Future<dynamic> fetchBk(Map<String, dynamic> params) async {
    final html = await getHtml(params['url']);
    debugPrint("请求分页 ${params['url']}");
    final doc = parse(html);
    List<String> pageUrls = [];
    List<String> shares = [];
    // 第一页数据
    final pageOneElements = doc.querySelectorAll(".m-pager-box tbody tr a");
    for (int i = 0; i < pageOneElements.length; i += 2) {
      shares.add(pageOneElements[i].text);
    }
    // 最大页码
    final pageSizeElement = doc.querySelector(".body .m-pager .changePage:last");
    // 请求路径
    final hiddenParamBaseUrl = doc.querySelector(".m-pager-box #baseUrl");
    // 请求隐藏参数
    final hiddenParamQuery = doc.querySelector(".m-pager-box #requestQuery");
    int pageSize = int.parse(pageSizeElement!.attributes['page']!);
    String? hiddenParam = hiddenParamQuery?.attributes['value'];
    String? baseUrl = hiddenParamBaseUrl?.attributes['value'];
    debugPrint("pageSize: $pageSize, baseUrl:$baseUrl, hiddenParam: $hiddenParam");
    for (int i = 2; i <= pageSize; i++) {
      String pageUrl = _buildBkPageUrl(i, baseUrl!, hiddenParam!, params['code']);
      pageUrls.add(pageUrl);
    }
    // 继续请求剩下的分页数据
    for (int i = 0; i < pageUrls.length; i++) {
      final htmlPage = await getHtml(pageUrls[i]);
      debugPrint("请求分页 ${pageUrls[i]}");
      final docPage = parse(htmlPage);
      // 分页数据
      final pageElements = docPage.querySelectorAll(".m-pager-box tbody tr a");
      for (int i = 0; i < pageElements.length; i += 2) {
        shares.add(pageElements[i].text);
      }
      // 随机延时
      final random = Random();
      int delaySeconds = 1 + random.nextInt(2); // 随机 1~2 秒
      await Future.delayed(Duration(seconds: delaySeconds));
    }
    return shares;
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
