import 'dart:convert';

import 'package:irich/service/api_provider_capabilities.dart';
import 'package:irich/service/api_service.dart';
import 'package:irich/types/stock.dart';
import 'package:irich/utils/chinese_pin_yin.dart';
import 'package:irich/utils/date_time.dart';
import 'package:irich/utils/file_tool.dart';
import 'package:irich/utils/rich_result.dart';
import 'package:irich/utils/trie.dart';
import 'package:path_provider/path_provider.dart';

class StoreQuote {
  static final List<Share> _shares = []; // 股票行情数据，交易时间需要每隔1s定时刷新，非交易时间读取本地文件
  static final Map<String, Share> _shareMap = {}; // 股票代码映射表，App启动时映射一次即可
  static final Map<String, List<Share>> _industryShares = {}; // 按行业名称分类的股票集合
  static final Map<String, List<Share>> _conceptShares = {}; // 按概念分类的股票集合
  static final Map<String, List<Share>> _provinceShares = {}; // 按省份分类的股票集合
  static final Trie _trie = Trie(); // 股票Trie树，支持模糊查询
  static bool _indexed = false; // 是否已经建立索引文件
  static late String _pathDataFileQuote;
  static late String _pathIndexFileProvince; // 股票=>省份索引文件[东方财富]
  static late String _pathIndexFileIndustry; // 股票=>行业索引文件[东方财富]
  static late String _pathIndexFileConcept; // 股票=>概念索引文件[东方财富]

  /// 私有构造函数防止实例化
  StoreQuote._();

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
    _pathDataFileQuote = "${appDir.path}/quote.ida";
    _pathIndexFileProvince = "${appDir.path}/province.idx";
    _pathIndexFileIndustry = "${appDir.path}/industry.idx";
    _pathIndexFileConcept = "${appDir.path}/concept.idx";
  }

  /// 爬取当前行情/行业板块/地域板块/股票行情基本信息
  static Future<RichResult> _fetchQuoteBasicInfo() async {
    ApiService().fetch(EnumApiType.quote,"");
    ApiService().fetch(EnumApiType.sideMenu,"");
    // 建立股票行情数据索引
    if (!_indexed) {
      _indexed = true;
      _buildShareMap(shares);
      _buildShareClassfier(shares);
      _buildShareTrie(shares);
    }
    return success();
  }

  /// 获取所有股票列表
  static Future<RichResult> load() async {
    await _initializePaths();
    // 用户第一次启动iRich，异步爬取当前行情/行业板块/地域板块/股票基本信息
    if (!await FileTool.isFileExist(_pathDataFileQuote) ||
        !await FileTool.isFileExist(_pathIndexFileProvince) ||
        !await FileTool.isFileExist(_pathIndexFileIndustry) ||
        !await FileTool.isFileExist(_pathIndexFileConcept)) {
      return _fetchQuoteBasicInfo();
    }
    // 1. 检查本地文件中是否存在股票行情数据
    if (await FileTool.isDailyFileExpired(_pathDataFileQuote)) {
      // 过期了要求拉取数据
      if (betweenTimePeriod("09:00", "09:29")) {
        // 这个时间段不能拉取,只加载本地过期股票行情数据
        return await _loadQuoteFile(_pathDataFileQuote, _shares);
      } else {
        final (result, shares as List<Share>) = await ApiService().fetch(
          EnumApiType.quote,
          "",
        );
        if (!result.ok()) {
          return error(RichStatus.networkError);
        }
      }
      return success();
    }
    final result = await _loadQuoteFile(_pathDataFileQuote, _shares);
    if (!result.ok()) {
      final (result, shares as List<Share>) = await ApiService().fetch(
        EnumApiType.quote,
        "",
      );
      if (!result.ok()) {
        return error(RichStatus.networkError);
      }
      return success();
    } // 步骤1. 恢复 m_market_shares 数据

    return error(RichStatus.fileDirty);
  }

  /// 加载本地行情数据文件
  static Future<RichResult> _loadQuoteFile(
    String path,
    List<Share> shares,
  ) async {
    try {
      String data = await FileTool.loadFile(path);
      dynamic arr = jsonDecode(data);
      if (arr == null || arr.size() < 1000) {
        return error(RichStatus.fileDirty);
      }
      shares.clear();
      for (final item in arr) {
        Share share = Share(
          name: item['name'], // 股票名称
          code: item['code'], // 股票代码
          market: Market.fromValue(item['market']), // 股票市场
          priceYesterdayClose: double.parse(
            item['price_yesterday_close'],
          ), // 昨天收盘价
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
}
