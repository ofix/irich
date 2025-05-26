// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/store_quote.dart
// Purpose:     quote store
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:irich/components/progress_popup.dart';
import 'package:irich/global/config.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/service/task_scheduler.dart';
import 'package:irich/service/tasks/task_sync_share_bk.dart';
import 'package:irich/service/tasks/task_sync_share_concept.dart';
import 'package:irich/service/tasks/task_sync_share_industry.dart';
import 'package:irich/service/tasks/task_sync_share_quote.dart';
import 'package:irich/service/tasks/task_sync_share_region.dart';
import 'package:irich/utils/chinese_pinyin.dart';
import 'package:irich/utils/file_tool.dart';
import 'package:irich/utils/rich_result.dart';
import 'package:irich/utils/trie.dart';

class StoreQuote {
  static List<Share> _shares = []; // 股票行情数据，交易时间需要每隔1s定时刷新，非交易时间读取本地文件
  static final Map<String, Share> _shareMap = {}; // 股票代码映射表，App启动时映射一次即可
  static final Map<String, List<Share>> _industryShares = {}; // 按行业名称分类的股票集合
  static final Map<String, List<Share>> _conceptShares = {}; // 按概念分类的股票集合
  static final Map<String, List<Share>> _provinceShares = {}; // 按省份分类的股票集合
  static final Trie _trie = Trie(); // 股票Trie树，支持模糊查询
  static String _pathDataFileQuote = "";
  static String _pathIndexFileProvince = ""; // 股票=>省份索引文件[东方财富]
  static String _pathIndexFileIndustry = ""; // 股票=>行业索引文件[东方财富]
  static String _pathIndexFileConcept = ""; // 股票=>概念索引文件[东方财富]
  static final StreamController<TaskProgress> _progressController =
      StreamController<TaskProgress>(); // 下载异步事件流
  static bool _loaded = false;

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
    _pathDataFileQuote = await Config.pathDataFileQuote;
    _pathIndexFileProvince = await Config.pathMapFileProvince;
    _pathIndexFileIndustry = await Config.pathMapFileIndustry;
    _pathIndexFileConcept = await Config.pathMapFileConcept;
  }

  static Future<bool> isQuoteExtraDataReady() async {
    await _initializePaths();
    if (!await FileTool.isFileExist(_pathDataFileQuote) ||
        !await FileTool.isFileExist(_pathIndexFileProvince) ||
        !await FileTool.isFileExist(_pathIndexFileIndustry) ||
        !await FileTool.isFileExist(_pathIndexFileConcept)) {
      return false;
    }
    return true;
  }

  /// 获取所有股票列表
  static Future<RichResult> load() async {
    if (_loaded) {
      return success();
    }
    _loaded = true;
    await _initializePaths();
    final scheduler = await TaskScheduler.getInstance();
    // 检查行情数据文件是否存在且没有过期
    if (!await FileTool.isFileExist(_pathDataFileQuote) ||
        await FileTool.isDailyFileExpired(_pathDataFileQuote)) {
      _shares = await scheduler.addTask(TaskSyncShareQuote(params: {}));
      await _saveQuoteFile(await Config.pathDataFileQuote, _shares);
      _buildShareMap(_shares);
    } else {
      final result = await _loadQuoteFile(_pathDataFileQuote, _shares);
      if (!result.ok()) {
        _shares = await scheduler.addTask(TaskSyncShareQuote(params: {}));
        await _saveQuoteFile(await Config.pathDataFileQuote, _shares);
      }
      _buildShareMap(_shares);
    }
    // 检查本地 地域/行业/概念板块 文件是否都存在
    if (await FileTool.isFileExist(_pathIndexFileProvince) &&
        !await FileTool.isWeekFileExpired(_pathIndexFileProvince) &&
        await FileTool.isFileExist(_pathIndexFileIndustry) &&
        !await FileTool.isWeekFileExpired(_pathIndexFileIndustry) &&
        await FileTool.isFileExist(_pathIndexFileConcept) &&
        !await FileTool.isWeekFileExpired(_pathIndexFileConcept)) {
      await loadLocalProvinceFile();
      await loadLocalIndustryFile();
      await loadLocalConceptFile();
      _buildShareTrie(_shares);
      return success();
    }

    final responseBk = await scheduler.addTask(TaskSyncShareBk(params: {}));
    // 如果本地地域板块文件不存在或者过期，则创建下载任务，否则直接加载本地数据
    if (!await FileTool.isFileExist(_pathIndexFileProvince) ||
        await FileTool.isWeekFileExpired(_pathIndexFileProvince)) {
      scheduler.addTask(TaskSyncShareRegion(params: responseBk[0]));
    } else {
      await loadLocalProvinceFile();
    }

    // 如果本地行业板块文件不存在或者过期，则创建下载任务，否则直接加载本地数据
    if (!await FileTool.isFileExist(_pathIndexFileIndustry) ||
        await FileTool.isWeekFileExpired(_pathIndexFileIndustry)) {
      scheduler.addTask(TaskSyncShareIndustry(params: responseBk[1]));
    } else {
      await loadLocalIndustryFile();
    }

    // 如果本地概念板块文件不存在或者过期，则创建下载任务，否则直接加载本地数据
    if (!await FileTool.isFileExist(_pathIndexFileConcept) ||
        await FileTool.isWeekFileExpired(_pathIndexFileConcept)) {
      scheduler.addTask(TaskSyncShareConcept(params: responseBk[2]));
    } else {
      await loadLocalConceptFile();
    }
    return success();
  }

  static Future<bool> _saveQuoteFile(String filePath, List<Share> shares) async {
    String data = _dumpQuote(shares);
    return FileTool.saveFile(filePath, data);
  }

  static String _dumpQuote(List<Share> shares) {
    final result = <Map<String, dynamic>>[];

    for (final share in shares) {
      final jsonObj = <String, dynamic>{
        'Code': share.code,
        'Name': share.name,
        'Market': share.market.market,
        'PriceYesterdayClose': share.priceYesterdayClose,
        'PriceNow': share.priceNow,
        'PriceMin': share.priceMin,
        'PriceMax': share.priceMax,
        'PriceOpen': share.priceOpen,
        'PriceClose': share.priceClose ?? share.priceNow,
        'PriceAmplitude': share.priceAmplitude,
        // 'ChangeAmount': share.changeAmount,
        'ChangeRate': share.changeRate,
        'Volume': share.volume,
        'Amount': share.amount,
        'TurnoverRate': share.turnoverRate,
        'Qrr': share.qrr,
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
      List<dynamic> rawList = jsonDecode(data) as List<dynamic>;
      List<Map<String, dynamic>> arr = rawList.cast<Map<String, dynamic>>();
      if (arr.length < 1000) {
        return error(RichStatus.fileDirty);
      }
      shares.clear();
      for (final item in arr) {
        Share share = Share(
          name: item['Name'], // 股票名称
          code: item['Code'], // 股票代码
          market: Market.fromVal(item['Market']), // 股票市场
          priceYesterdayClose: item['PriceYesterdayClose'] as double, // 昨天收盘价
          priceNow: item['PriceNow'] as double, // 当前价
          priceMin: item['PriceMin'] as double, // 最低价
          priceMax: item['PriceMax'] as double, // 最高价
          priceOpen: item['PriceOpen'] as double, // 开盘价
          priceClose: item['PriceClose'] as double, // 收盘价
          priceAmplitude: item['PriceAmplitude'] as double, // 股价振幅
          // changeAmount: item['ChangeAmount'] as double, // 涨跌额
          changeRate: item['ChangeRate'] as double, // 涨跌幅度
          volume: item['Volume'] as int, // 成交量
          amount: item['Amount'] as double, // 成交额
          turnoverRate: item['TurnoverRate'] as double, // 换手率
          qrr: item['Qrr'] as double, // 量比
        );
        shares.add(share);
      }
    } catch (e, stackTrace) {
      debugPrint("Error loading Quote file: $e");
      debugPrint(stackTrace.toString());
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

  /// 构建股票Trie树
  static Future<void> _buildShareTrie(List<Share> shares) async {
    for (final share in shares) {
      _trie.insert(share.name, share.code);
      _trie.insert(share.code, share.code);
      // 插入拼音
      List<String> pinyin = await ChinesePinYin.getFirstLetters(share.name);
      for (final char in pinyin) {
        _trie.insert(char.toLowerCase(), share.code);
      }
    }
  }

  // 加载本地股票地域文件数据
  static Future<void> loadLocalProvinceFile() async {
    String data = await FileTool.loadFile(await Config.pathMapFileProvince);
    List<dynamic> rawList = jsonDecode(data) as List<dynamic>;
    List<Map<String, dynamic>> provinces = rawList.cast<Map<String, dynamic>>();
    fillShareProvince(provinces);
  }

  // 填充所有股票的地域字段，地域和股票列表的内存映射
  static void fillShareProvince(List<Map<String, dynamic>> provinces) {
    for (final province in provinces) {
      final shares = province['Shares'];
      for (final shareCode in shares) {
        Share? share = _shareMap[shareCode];
        if (share != null) {
          share.province = province['Name'];
          _provinceShares.putIfAbsent(province['Name'], () => []).add(share);
        }
      }
    }
  }

  // 加载本地股票行业文件数据
  static Future<void> loadLocalIndustryFile() async {
    String data = await FileTool.loadFile(await Config.pathMapFileIndustry);
    List<dynamic> rawList = jsonDecode(data) as List<dynamic>;
    List<Map<String, dynamic>> industries = rawList.cast<Map<String, dynamic>>();
    fillShareIndustry(industries);
  }

  // 填充所有股票行业字段，行业和股票列表的内存映射
  static void fillShareIndustry(List<Map<String, dynamic>> industries) {
    for (final industry in industries) {
      final shares = industry['Shares'];
      for (final shareCode in shares) {
        Share? share = _shareMap[shareCode];
        if (share != null) {
          share.industryName = industry['Name'];
          _industryShares.putIfAbsent(industry['Name'], () => []).add(share);
        }
      }
    }
  }

  // 加载本地股票概念文件数据
  static Future<void> loadLocalConceptFile() async {
    String data = await FileTool.loadFile(await Config.pathMapFileConcept);
    List<dynamic> rawList = jsonDecode(data) as List<dynamic>;
    List<Map<String, dynamic>> concepts = rawList.cast<Map<String, dynamic>>();
    fillShareConcept(concepts);
  }

  // 填充所有概念和股票列表的内存映射
  static void fillShareConcept(List<Map<String, dynamic>> concepts) {
    for (final concept in concepts) {
      final shares = concept['Shares'];
      final conceptName = concept['Name'];
      for (final shareCode in shares) {
        Share? share = _shareMap[shareCode];
        if (share != null) {
          _conceptShares.putIfAbsent(conceptName, () => []).add(share);
        }
      }
    }
  }
}
