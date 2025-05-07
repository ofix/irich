import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:irich/components/progress_popup.dart';
import 'package:irich/global/config.dart';
import 'package:irich/service/api_provider_capabilities.dart';
import 'package:irich/service/api_service.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/utils/chinese_pin_yin.dart';
import 'package:irich/utils/date_time.dart';
import 'package:irich/utils/file_tool.dart';
import 'package:irich/utils/rich_result.dart';
import 'package:irich/utils/trie.dart';
import 'package:path_provider/path_provider.dart';

class StoreQuote {
  static List<Share> _shares = []; // 股票行情数据，交易时间需要每隔1s定时刷新，非交易时间读取本地文件
  static Map<String, Share> _shareMap = {}; // 股票代码映射表，App启动时映射一次即可
  static Map<String, List<Share>> _industryShares = {}; // 按行业名称分类的股票集合
  static Map<String, List<Share>> _conceptShares = {}; // 按概念分类的股票集合
  static Map<String, List<Share>> _provinceShares = {}; // 按省份分类的股票集合
  static final Trie _trie = Trie(); // 股票Trie树，支持模糊查询
  static bool _indexed = false; // 是否已经建立索引文件
  static String _pathDataFileQuote = "";
  static String _pathIndexFileProvince = ""; // 股票=>省份索引文件[东方财富]
  static String _pathIndexFileIndustry = ""; // 股票=>行业索引文件[东方财富]
  static String _pathIndexFileConcept = ""; // 股票=>概念索引文件[东方财富]
  static final StreamController<TaskProgress> _progressController =
      StreamController<TaskProgress>(); // 下载异步事件流

  /// 私有构造函数防止实例化
  StoreQuote._();

  /// 获取某个行业分类的所有股票
  static List<Share> getByIndustry(String industry) {
    return _industryShares[industry] ?? [];
  }

  /// 获取某个概念板块的所有股票
  static List<Share> getByConcept(String concept) {
    return _conceptShares[concept] ?? [];
  }

  /// 获取某个省份的所有股票
  static List<Share> getByProvince(String province) {
    return _provinceShares[province] ?? [];
  }

  /// 获取所有行业分类名称
  static List<String> get industries => _industryShares.keys.toList();

  /// 获取所有概念分类名称
  static List<String> get concepts => _conceptShares.keys.toList();

  /// 获取所有省份分类名称
  static List<String> get provinces => _provinceShares.keys.toList();

  /// 获取所有股票列表
  static List<Share> get shares => _shares;

  /// 获取加载进度流
  static Stream<TaskProgress> get progressStream => _progressController.stream;

  /// 根据用户输入的前缀字符返回对应的股票列表
  List<Share> searchShares(String prefix) {
    List<String> shareCodes = _trie.listPrefixWith(prefix);
    for (final shareCode in shareCodes) {
      final share = _shareMap[shareCode];
      if (share != null) {
        shares.add(share);
      }
    }
    return shares;
  }

  static Future<void> _initializePaths() async {
    final appDir = await getApplicationDocumentsDirectory();
    _pathDataFileQuote = "${appDir.path}/quote.json";
    _pathIndexFileProvince = "${appDir.path}/province.json";
    _pathIndexFileIndustry = "${appDir.path}/industry.json";
    _pathIndexFileConcept = "${appDir.path}/concept.json";
  }

  static Future<bool> isQuoteExtraDataReady() async {
    _initializePaths();
    if (!await FileTool.isFileExist(_pathDataFileQuote) ||
        !await FileTool.isFileExist(_pathIndexFileProvince) ||
        !await FileTool.isFileExist(_pathIndexFileIndustry) ||
        !await FileTool.isFileExist(_pathIndexFileConcept)) {
      return false;
    }
    return true;
  }

  /// 填充所有股票的地域字段
  static void _fillShareProvince(List<Map<String, dynamic>> provinces) {
    for (final province in provinces) {
      final shares = province['shares'];
      for (final shareCode in shares) {
        Share? share = _shareMap[shareCode];
        if (share != null) {
          share.province = province['name'];
        }
      }
    }
  }

  /// 填充所有股票的行业字段
  static void _fillShareIndustry(List<Map<String, dynamic>> industries) {
    for (final industry in industries) {
      final shares = industry['shares'];
      for (final shareCode in shares) {
        Share? share = _shareMap[shareCode];
        if (share != null) {
          share.industryName = industry['name'];
        }
      }
    }
  }

  /// 爬取当前行情/行业板块/地域板块/股票行情基本信息
  static Future<RichResult> _fetchQuoteBasicInfo() async {
    // 爬取当前行情
    _progressController.add(TaskProgress(name: "市场行情", current: 0, total: 100, desc: "获取A股市场行情数据"));
    final (statusQuote, responseQuote as List<Share>) = await ApiService(
      ProviderApiType.quote,
    ).fetch("");
    if (statusQuote.ok()) {
      _shares = responseQuote;
      _buildShareMap(_shares);

      // 保存行情数据到文件
      await _saveQuoteFile(await Config.pathDataFileQuote, _shares);
    }

    // 爬取板块数据
    _progressController.add(TaskProgress(name: "板块分类", current: 0, total: 100, desc: "获取板块分类数据"));
    // 继续异步爬取 行业/地域/概念板块数据
    final (statusMenu, responseQuoteExtra as List<List<Map<String, dynamic>>>) = await ApiService(
      ProviderApiType.quoteExtra,
    ).fetch("");
    if (statusMenu.ok()) {
      // 计算总共需要爬取的板块数量
      int totalBk = 0;
      int recvBk = 0;
      final bkList = [ProviderApiType.province, ProviderApiType.industry, ProviderApiType.concept];
      final bkName = ["地域板块", "行业板块", "概念板块"];
      final bkPath = [
        await Config.pathMapFileProvince,
        await Config.pathMapFileIndustry,
        await Config.pathMapFileConcept,
      ];
      for (final item in responseQuoteExtra) {
        totalBk += item.length;
      }
      debugPrint("请求的板块总数: $totalBk");
      _progressController.add(
        TaskProgress(name: "板块分类", current: recvBk, total: totalBk, desc: "获取板块分类数据"),
      );
      // 依次爬取各个板块数据(省份/行业/概念)
      for (int i = 0; i < responseQuoteExtra.length; i++) {
        // 异步并发爬爬取省份板块
        final (statusBk, responseBk) = await ApiService(bkList[i]).batchFetch(
          responseQuoteExtra[i],
          (Map<String, dynamic> params, String providerName) {
            recvBk += 1;
            _progressController.add(
              TaskProgress(
                name: bkName[i],
                current: recvBk,
                total: totalBk,
                desc: "$providerName : ${params['name']}",
              ),
            );
          },
        );
        if (statusBk.ok()) {
          final bkJson = <Map<String, dynamic>>[];
          for (final item in responseBk) {
            final bkItem = <String, dynamic>{};
            bkItem['code'] = item['param']['code']; // 板块代号
            bkItem['name'] = item['param']['name']; // 板块名称
            bkItem['pinyin'] = item['param']['pinyin']; // 板块拼音
            bkItem['shares'] = item['response']; //板块成分股代码
            bkJson.add(bkItem);
          }
          final data = jsonEncode(bkJson);
          debugPrint("写入文件 ${bkPath[i]}");
          // 填充所有股票行业字段
          if (i == 0) {
            _fillShareProvince(bkJson);
          } else if (i == 1) {
            _fillShareIndustry(bkJson);
          }
          // 存储到缓存和文件
          await FileTool.saveFile(bkPath[i], data);
        }
      }
    }

    // 爬取完成后建立股票行情数据索引
    if (!_indexed) {
      _indexed = true;
      _buildShareClassfier(shares);
      // _buildShareTrie(shares);
    }
    return success();
  }

  /// 获取所有股票列表
  static Future<RichResult> load() async {
    await _initializePaths();
    // 用户第一次启动iRich，异步爬取当前行情/行业板块/地域板块/股票基本信息
    if (!await isQuoteExtraDataReady()) {
      return _fetchQuoteBasicInfo();
    }
    // 1. 检查本地文件中是否存在股票行情数据
    if (await FileTool.isDailyFileExpired(_pathDataFileQuote)) {
      // 过期了要求拉取数据
      if (betweenTimePeriod("09:00", "09:29")) {
        // 这个时间段不能拉取,只加载本地过期股票行情数据
        return await _loadQuoteFile(_pathDataFileQuote, _shares);
      } else {
        final (result, shares as List<Share>) = await ApiService(ProviderApiType.quote).fetch("");
        if (!result.ok()) {
          return error(RichStatus.networkError);
        }
      }
      return success();
    }
    final result = await _loadQuoteFile(_pathDataFileQuote, _shares);
    if (!result.ok()) {
      final (result, shares as List<Share>) = await ApiService(ProviderApiType.quote).fetch("");
      if (!result.ok()) {
        return error(RichStatus.networkError);
      }
      return success();
    } // 步骤1. 恢复 m_market_shares 数据

    return error(RichStatus.fileDirty);
  }

  static Future<bool> _saveQuoteFile(String filePath, List<Share> shares) async {
    String data = _dumpQuote(shares);
    return FileTool.saveFile(filePath, data);
  }

  static String _dumpQuote(List<Share> shares) {
    final result = <Map<String, dynamic>>[];

    for (final share in shares) {
      final jsonObj = <String, dynamic>{
        'code': share.code,
        'name': share.name,
        'market': share.market.market,
        'price_yesterday_close': share.priceYesterdayClose,
        'price_now': share.priceNow,
        'price_min': share.priceMin,
        'price_max': share.priceMax,
        'price_open': share.priceOpen,
        'price_close': share.priceClose ?? share.priceNow,
        'price_amplitude': share.priceAmplitude,
        // 'change_amount': share.changeAmount,
        'change_rate': share.changeRate,
        'volume': share.volume,
        'amount': share.amount,
        'turnover_rate': share.turnoverRate,
        'qrr': share.qrr,
      };
      result.add(jsonObj);
    }
    const encoder = JsonEncoder.withIndent('    ');
    return encoder.convert(result);
  }

  /// 加载本地行情数据文件
  static Future<RichResult> _loadQuoteFile(String path, List<Share> shares) async {
    try {
      String data = await FileTool.loadFile(path);
      List<Map<String, dynamic>> arr = jsonDecode(data);
      if (arr.length < 1000) {
        return error(RichStatus.fileDirty);
      }
      shares.clear();
      for (final item in arr) {
        Share share = Share(
          name: item['name'], // 股票名称
          code: item['code'], // 股票代码
          market: Market.fromValue(item['market']), // 股票市场
          priceYesterdayClose: double.parse(item['price_yesterday_close']), // 昨天收盘价
          priceNow: double.parse(item['price_now']), // 当前价
          priceMin: double.parse(item['price_min']), // 最低价
          priceMax: double.parse(item['price_max']), // 最高价
          priceOpen: double.parse(item['price_open']), // 开盘价
          priceClose: double.parse(item['price_close']), // 收盘价
          priceAmplitude: double.parse(item['price_amplitude']), // 股价振幅
          changeAmount: double.parse(item['change_amount']), // 涨跌额
          changeRate: double.parse(item['change_rate']), // 涨跌幅度
          volume: int.parse(item['volume']), // 成交量
          amount: double.parse(item['amount']), // 成交额
          turnoverRate: double.parse(item['turnover_rate']), // 换手率
          qrr: double.parse(item['qrr']), // 量比
        );
        shares.add(share);
      }
    } catch (e) {
      print("Error loading file: $e");
      return error(RichStatus.fileDirty);
    }
    return success();
  }

  /// 根据股票代码获取股票信息
  static Share? query(String shareCode) {
    return _shareMap[shareCode];
  }

  /// 刷新股票行情数据,间隔一秒一次
  static Future<void> refresh() async {
    // 异步请求股票行情数据
    List<Share> shares = [];
    // 更新内存中数据
    for (final share in shares) {
      final existShare = _shareMap[share.code];
      if (existShare != null) {
        existShare.priceOpen = share.priceOpen;
        existShare.priceClose = share.priceClose;
        existShare.priceMax = share.priceMax;
        existShare.priceMin = share.priceMin;
        existShare.priceNow = share.priceNow;
        existShare.priceYesterdayClose = share.priceYesterdayClose;
        existShare.amount = share.amount;
        existShare.changeAmount = share.changeAmount;
        existShare.changeRate = share.changeRate;
        existShare.qrr = share.qrr;
      }
    }
    // 如果收盘后，检查本地文件是否已刷新最新行情数据，如果没有，则刷新本地文件，需要考虑非交易日
  }

  /// share_code => Share 内存映射，方便后续快速查找
  static void _buildShareMap(List<Share> shares) {
    for (final share in shares) {
      _shareMap[share.code] = share;
    }
  }

  // 构建股票分类器
  static void _buildShareClassfier(List<Share> shares) {
    for (final share in shares) {
      if (share.industry != null) {
        _industryShares.putIfAbsent(share.industry!.name, () => []).add(share);
      }
      if (share.concepts != null) {
        for (final concept in share.concepts!) {
          _conceptShares.putIfAbsent(concept.name, () => []).add(share);
        }
      }
      if (share.province != null) {
        _provinceShares.putIfAbsent(share.province!, () => []).add(share);
      }
    }
  }

  /// 构建股票Trie树
  static void _buildShareTrie(List<Share> shares) {
    for (final share in shares) {
      _trie.insert(share.name, share.code);
      _trie.insert(share.code, share.code);
      // 插入拼音
      List<String> pinyin = ChinesePinYin.getFirstLetters(share.name);
      for (final char in pinyin) {
        _trie.insert(char.toLowerCase(), share.code);
      }
    }
  }
}
