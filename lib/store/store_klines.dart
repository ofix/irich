// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/store/store_klines.dart
// Purpose:     klines memory cache
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:irich/service/api_provider_capabilities.dart';
import 'package:irich/service/api_service.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/service/lru_cache.dart';
import 'package:irich/utils/date_time.dart';
import 'package:irich/utils/file_tool.dart';
import 'package:irich/utils/rich_result.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class RichRef<T> {
  T value;
  RichRef(this.value);
}

typedef KlineResult = (RichResult result, List<UiKline> klines);
typedef MinuteKlineResult = (RichResult result, List<MinuteKline> minuteKlines);

/// K线数据存储类
/// 1. 支持内存缓存300只股票
/// 2. 所有网络请求均为异步请求
class StoreKlines {
  final List<LRUCache<String, List<UiKline>>> _lruCacheKlines = [
    LRUCache<String, List<UiKline>>(capacity: 300), // 日K线LRU缓存
    LRUCache<String, List<UiKline>>(capacity: 300), // 周K线LRU缓存
    LRUCache<String, List<UiKline>>(capacity: 300), // 月K线LRU缓存
    LRUCache<String, List<UiKline>>(capacity: 300), // 季K线LRU缓存
    LRUCache<String, List<UiKline>>(capacity: 300), // 年K线LRU缓存
  ];
  final List<LRUCache<String, List<MinuteKline>>> _lruCacheMinuteKlines = [
    LRUCache<String, List<MinuteKline>>(capacity: 300), // 分时K线LRU缓存
    LRUCache<String, List<MinuteKline>>(capacity: 300), // 五日分时K线LRU缓存
  ];

  // 必须单例模式
  static final StoreKlines _instance = StoreKlines._internal();
  factory StoreKlines() => _instance;
  StoreKlines._internal();

  /// 获取单个股票分时K线
  Future<MinuteKlineResult> queryMinuteKlines(String shareCode) async {
    List<MinuteKline>? cachedMinuteKlines = _lruCacheMinuteKlines[0].get(shareCode);
    if (cachedMinuteKlines != null) {
      return (success(), cachedMinuteKlines);
    }
    // 缓存不存在
    final (result, newestMinuteKlines as List<MinuteKline>) = await ApiService(
      ProviderApiType.minuteKline,
    ).fetch(shareCode);
    if (result.ok()) {
      _lruCacheMinuteKlines[0].put(shareCode, newestMinuteKlines); // 缓存最近300条记录
    }
    return (result, newestMinuteKlines);
  }

  /// 获取单个股票5日分时K线
  Future<MinuteKlineResult> queryFiveDayMinuteKlines(String shareCode) async {
    List<MinuteKline>? cachedFiveDayMinuteKlines = _lruCacheMinuteKlines[1].get(shareCode);
    if (cachedFiveDayMinuteKlines != null) {
      return (success(), cachedFiveDayMinuteKlines);
    }
    // 缓存不存在
    final (result, newestFiveDayMinuteKlines as List<MinuteKline>) = await ApiService(
      ProviderApiType.fiveDayKline,
    ).fetch(shareCode);
    if (result.ok()) {
      _lruCacheMinuteKlines[1].put(shareCode, newestFiveDayMinuteKlines); // 缓存最近300条记录
    }
    return (result, newestFiveDayMinuteKlines);
  }

  /// 获取单个票周K线
  Future<KlineResult> queryWeekKlines(String shareCode) async {
    return _queryPeriodKlines(shareCode, _lruCacheKlines[1], _generateWeekKLines);
  }

  /// 获取单个股票月K线
  Future<KlineResult> queryMonthKlines(String shareCode) async {
    return _queryPeriodKlines(shareCode, _lruCacheKlines[2], _generateMonthKlines);
  }

  /// 获取单个股票季K线
  Future<KlineResult> queryQuarterKlines(String shareCode) async {
    return _queryPeriodKlines(shareCode, _lruCacheKlines[3], _generateQuarterKlines);
  }

  /// 获取单个股票年K线
  Future<KlineResult> queryYearKlines(String shareCode) async {
    return _queryPeriodKlines(shareCode, _lruCacheKlines[4], _generateYearKlines);
  }

  /// 获取单个股票日K线
  /// 1. 检查内存中是否缓存
  /// 2. 检查文件中是否缓存
  /// 3. 文件中K线如果过期，刷新
  Future<KlineResult> queryDayKlines(String shareCode) async {
    // 检查内存缓存是否存在
    List<UiKline>? cachedDayKlines = _lruCacheKlines[0].get(shareCode);
    if (cachedDayKlines != null) {
      return (success(), cachedDayKlines);
    }

    String filePath = await _getFilePathOfDayKline(shareCode);
    List<UiKline> newestDayKlines = [];
    RichResult result;
    if (await FileTool.isFileExist(filePath)) {
      if (await FileTool.isDailyFileExpired(filePath)) {
        result = await _fetchIncrementalDayKlines(shareCode, newestDayKlines); // 增量爬取
        if (!result.ok()) {
          // 爬取增量K线数据失败
          return (result, newestDayKlines);
        }
        result = await _saveIncrementalDayKlines(shareCode, newestDayKlines);
        if (!result.ok()) {
          // 保存增量K线数据失败
          return (result, newestDayKlines);
        }
      }
      result = await _loadLocalDayKlines(shareCode, newestDayKlines); // 加载全量数据
    } else {
      (result, newestDayKlines as List<UiKline>) = await ApiService(
        ProviderApiType.dayKline,
      ).fetch(shareCode); // 全量爬取
      if (!result.ok()) {
        return (result, newestDayKlines); // 全量爬取失败
      }
      result = await _saveShareDayKline(shareCode, newestDayKlines); // 保存到文件
    }
    if (!result.ok()) {
      return (result, newestDayKlines);
    }
    _lruCacheKlines[0].put(shareCode, newestDayKlines); // 缓存到内存
    return (result, newestDayKlines);
  }

  /// 获取指定时间范围K线工具辅助函数
  Future<KlineResult> _queryPeriodKlines(
    String shareCode,
    LRUCache<String, List<UiKline>> lruCache,
    List<UiKline> Function(List<UiKline>) generateCallback,
  ) async {
    List<UiKline>? cachedKlines = lruCache.get(shareCode);
    if (cachedKlines != null) {
      return (success(), cachedKlines);
    }
    // 检查日K线缓存，如果不存在或者过期，需要重新拉取
    final (result, dayKlines) = await queryDayKlines(shareCode);
    if (!result.ok()) {
      return (result, dayKlines);
    }
    // 根据最新的日K线，计算 周/月/季/年K线
    List<UiKline> periodKlines = generateCallback(dayKlines); // 计算数据
    lruCache.put(shareCode, periodKlines); // 将计算好的 周/月/季/年K线缓存到内存中
    return (success(), periodKlines);
  }

  /// Calculates number of weeks for a given year as per https://en.wikipedia.org/wiki/ISO_week_date#Weeks_per_year
  int numOfWeeks(int year) {
    DateTime dec28 = DateTime(year, 12, 28);
    int dayOfDec28 = int.parse(DateFormat("D").format(dec28));
    return ((dayOfDec28 - dec28.weekday + 10) / 7).floor();
  }

  bool _getYearWeek(String day, RichRef<int> week) {
    try {
      final date = DateTime.parse(day);
      int dayOfYear = int.parse(DateFormat("D").format(date));
      int woy = ((dayOfYear - date.weekday + 10) / 7).floor();
      if (woy < 1) {
        woy = numOfWeeks(date.year - 1);
      } else if (woy > numOfWeeks(date.year)) {
        woy = 1;
      }
      week.value = woy;
      return true;
    } catch (e) {
      debugPrint("error:${e.toString()}");
      return false; // 格式错误或无效日期
    }
  }

  bool _getYearMonth(String day, RichRef<int> month) {
    String m = day.substring(5, 7);
    if (m[0] == '0') {
      month.value = int.parse(m.substring(1, 2));
      return true;
    }
    month.value = int.parse(m);
    return true;
  }

  bool _getYearQuarter(String day, RichRef<int> quarter) {
    RichRef<int> month = RichRef<int>(0);
    _getYearMonth(day, month);
    quarter.value = (month.value / 4 + 1).toInt();
    return true;
  }

  bool _getYear(String day, RichRef<int> year) {
    String y = day.substring(0, 4);
    year.value = int.parse(y); // atoi
    return true;
  }

  // --- 关键辅助函数 ---
  UiKline _copyKline(UiKline src) {
    return UiKline(
      day: src.day,
      marketCap: src.marketCap,
      changeRate: src.changeRate,
      changeAmount: src.changeAmount,
      volume: src.volume,
      amount: src.amount,
      priceOpen: src.priceOpen,
      priceClose: src.priceClose,
      priceMax: src.priceMax,
      priceMin: src.priceMin,
      priceNow: src.priceNow,
      turnoverRate: src.turnoverRate,
      danger: src.danger,
      favorite: src.favorite,
    );
  }

  List<UiKline> _generatePeriodKlines(
    List<UiKline> dayKlines,
    bool Function(String, RichRef<int>) periodFunc,
  ) {
    List<UiKline> klines = [];
    UiKline kline;
    RichRef<int> prevPeriod = RichRef<int>(0);
    RichRef<int> currPeriod = RichRef<int>(0);
    double prevPeriodPriceClose = 0.0;
    String periodStartDay = "";

    periodStartDay = dayKlines[0].day;
    kline = _copyKline(dayKlines[0]); // 必须深度拷贝，否则价格会错乱

    periodFunc(periodStartDay, prevPeriod);
    prevPeriodPriceClose = (dayKlines[0]).priceMin; // 将第一天上市的最低价(发行价)作为基准价

    for (int i = 1; i < dayKlines.length; i++) {
      UiKline dayKline = dayKlines[i];
      periodFunc(dayKline.day, currPeriod); // 当前是第几周，第几月, 第几季，第几年
      if (currPeriod.value != prevPeriod.value) {
        // 保存上一周的周K线
        kline.priceClose = dayKlines[i - 1].priceClose; // 将上一个交易日的收盘价作为周期收盘价
        kline.day = periodStartDay; // 周期开盘日是周期第一天
        kline.changeRate = (kline.priceClose - prevPeriodPriceClose) / prevPeriodPriceClose; // 周涨跌幅
        kline.changeAmount = kline.priceClose - prevPeriodPriceClose; // 周涨跌额
        klines.add(kline);
        prevPeriodPriceClose = kline.priceClose; // 将上一个交易日的收盘价作为周收盘价
        //////////// 初始化本周K线数据
        periodStartDay = dayKline.day;
        prevPeriod.value = currPeriod.value;
        kline = _copyKline(dayKline);
      } else {
        kline.marketCap = dayKline.marketCap; // 股票市值
        kline.volume += dayKline.volume; // 周期成交量
        kline.amount += dayKline.amount; // 周期成交额
        kline.turnoverRate += dayKline.turnoverRate; // 周期换手率
        if (dayKline.priceMax > kline.priceMax) {
          kline.priceMax = dayKline.priceMax;
        }
        if (dayKline.priceMin < kline.priceMin) {
          kline.priceMin = dayKline.priceMin;
        }
      }
    }

    ////////// 剩余未添加的记录 ////////
    kline.priceClose = dayKlines[dayKlines.length - 1].priceClose; // 周收盘价是最后一个交易日的收盘价
    kline.changeRate = (kline.priceClose - prevPeriodPriceClose) / prevPeriodPriceClose; // 周涨跌幅
    kline.changeAmount = kline.priceClose - prevPeriodPriceClose; // 周涨跌额
    klines.add(kline);
    return klines;
  }

  // 计算周K线
  List<UiKline> _generateWeekKLines(List<UiKline> dayKlines) {
    return _generatePeriodKlines(dayKlines, _getYearWeek);
  }

  // 计算月K线
  List<UiKline> _generateMonthKlines(List<UiKline> dayKlines) {
    return _generatePeriodKlines(dayKlines, _getYearMonth);
  }

  // 计算季度K线
  List<UiKline> _generateQuarterKlines(List<UiKline> dayKlines) {
    return _generatePeriodKlines(dayKlines, _getYearQuarter);
  }

  // 计算年K线
  List<UiKline> _generateYearKlines(List<UiKline> dayKlines) {
    return _generatePeriodKlines(dayKlines, _getYear);
  }

  /// 序列化日K线数据
  String _flushDayKlines(List<UiKline> klines) {
    final lines = StringBuffer();
    for (final kline in klines) {
      lines
        ..write(kline.day)
        ..write(',')
        ..write(kline.priceOpen.toStringAsFixed(2))
        ..write(',')
        ..write(kline.priceClose.toStringAsFixed(2))
        ..write(',')
        ..write(kline.priceMax.toStringAsFixed(2))
        ..write(',')
        ..write(kline.priceMin.toStringAsFixed(2))
        ..write(',')
        ..write(kline.volume.toString())
        ..write(',')
        ..write(kline.amount.toStringAsFixed(2))
        ..write(',')
        ..write(kline.changeAmount.toStringAsFixed(2))
        ..write(',')
        ..write(kline.changeRate.toStringAsFixed(2))
        ..write(',')
        ..write(kline.turnoverRate.toStringAsFixed(2))
        ..write('\n');
    }
    return lines.toString();
  }

  /// 保存日K线数据到本地文件
  Future<RichResult> _saveShareDayKline(String shareCode, List<UiKline> klines) async {
    if (klines.isEmpty) {
      return error(RichStatus.parameterError);
    }
    String filePath = await _getFilePathOfDayKline(shareCode);
    String lines = _flushDayKlines(klines);
    bool result = await FileTool.saveFile(filePath, lines);
    if (!result) {
      return error(RichStatus.fileWriteFailed);
    }
    return success();
  }

  /// 保存增量日K线数据到本地文件
  Future<RichResult> _saveIncrementalDayKlines(String shareCode, List<UiKline> klines) async {
    if (klines.isEmpty) {
      return error(RichStatus.parameterError);
    }
    String lines = _flushDayKlines(klines);

    final filePath = await _getFilePathOfDayKline(shareCode);
    final file = File(filePath);

    try {
      await file.writeAsString(lines, mode: FileMode.append, encoding: utf8);
      return success();
    } catch (e) {
      return error(RichStatus.fileWriteFailed);
    }
  }

  /// 获取本地日K线文件缺失的K线数据
  Future<RichResult> _fetchIncrementalDayKlines(String shareCode, List<UiKline> dayKlines) async {
    String endDate = getDayFromNow(1); // 请求需要明天的日期，才能下载当天的K线
    String filePath = await _getFilePathOfDayKline(shareCode);
    final (result, lastLine) = await FileTool.getLastLineOfFile(filePath);
    if (!result || lastLine.trim() == "") {
      // 错误
      return error(RichStatus.fileDirty);
    }
    String startDate = lastLine.substring(0, 10);
    int ndays = diffDays(startDate, endDate);
    if (ndays <= 0) {
      return error(RichStatus.innerError);
    }

    final (state, newKlines as List<UiKline>) = await ApiService(
      ProviderApiType.dayKline,
    ).fetch(shareCode, {"endDate": endDate, "count": 144});
    if (!state.ok()) {
      return error(RichStatus.networkError);
    }
    // 倒序遍历，提升性能
    for (int i = newKlines.length - 1; i >= 0; i--) {
      UiKline kline = newKlines[i];
      if (kline.day == startDate) {
        // 日K线文件已经有当日K线数据，但不是最新的
        List<UiKline> copiedList = newKlines.sublist(i);
        dayKlines
          ..clear()
          ..addAll(copiedList);
        break;
      }
    }
    return success();
  }

  /// 获取本地日K线文件路径
  Future<String> _getFilePathOfDayKline(String shareCode) async {
    String currPath = await FileTool.getExecutableDir();
    return path.join(currPath, "data", "day", "$shareCode.csv");
  }

  /// 加载本地日K线数据
  Future<RichResult> _loadLocalDayKlines(String shareCode, List<UiKline> dayKlines) async {
    String filePath = await _getFilePathOfDayKline(shareCode);
    if (!await FileTool.isFileExist(filePath)) {
      return error(RichStatus.fileNotFound);
    }
    dayKlines.clear();
    String lines = await FileTool.loadFile(filePath);
    List<String> klines = lines.split("\n");
    bool dataDirty = false;
    for (String kline in klines) {
      int size = kline.length;
      if (size == 0) {
        continue;
      }
      if (size < 10) {
        dataDirty = true;
        break;
      }
      // 检查最后一个字符是否是\r,需要排除掉，否则会导致通过share_code无法找到Share*,进而股票行业和地域无法显示
      if (kline[kline.length - 1] == '\r') {
        kline = kline.substring(0, kline.length - 1);
      }
      List<String> fields = kline.split(",");
      UiKline uiKline = UiKline(
        day: fields[0],
        priceOpen: double.parse(fields[1]), // 开盘价
        priceClose: double.parse(fields[2]), // 收盘价
        priceMax: double.parse(fields[3]), // 最高价
        priceMin: double.parse(fields[4]), // 最低价
        volume: BigInt.from(int.parse(fields[5])), // 成交量
        amount: double.parse(fields[6]), // 成交额
        changeAmount: double.parse(fields[7]), // 涨跌额
        changeRate: double.parse(fields[8]), // 涨跌幅
        turnoverRate: double.parse(fields[9]), // 换手率
      );

      dayKlines.add(uiKline);
    }

    if (dataDirty) {
      // 数据污染了？
      dayKlines.clear();
      return error(RichStatus.fileDirty);
    }
    return success();
  }
}
