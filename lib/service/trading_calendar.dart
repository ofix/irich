// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/trading_calendar.dart
// Purpose:     trading calendar
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:irich/global/config.dart';
import 'package:irich/utils/file_tool.dart';

class TradingCalendar {
  // 静态单例实例
  static final TradingCalendar _instance = TradingCalendar._internal();
  late final Map<DateTime, String> _specialDays; // 特殊日期，比如临时休市
  late final Map<int, Set<DateTime>> _yearlyHolidays; // 按年排列的节假日
  bool _initialized = false;

  factory TradingCalendar() {
    return _instance;
  }

  // 私有构造函数
  TradingCalendar._internal();

  Future<void> initialize({String? timeZone, Set<DateTime>? holidays}) async {
    if (!_initialized) {
      _specialDays = {};
      _yearlyHolidays = await _loadYearlyHolidays();
      _initialized = true;
    }
  }

  // 加载日期
  Future<Map<int, Set<DateTime>>> _loadYearlyHolidays() async {
    Map<int, Set<DateTime>> yearlyHolidays = {};
    final data = await FileTool.loadFile(await Config.pathDataFileHoliday);
    final jsonData = json.decode(data);
    final holidaysList = jsonData['holidays'];

    for (final yearData in holidaysList) {
      final year = yearData['year'] as int;
      final holidays = yearData['holidays'];
      final dateSet = <DateTime>{};
      for (final holiday in holidays) {
        for (final dateStr in (holiday['dates'])) {
          final dateParts = dateStr.split('-');
          final date = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );
          dateSet.add(date);
        }
      }
      yearlyHolidays[year] = dateSet;
    }
    return yearlyHolidays;
  }

  // 判断是否是交易日
  bool isTradingDay([DateTime? date]) {
    date ??= DateTime.now();
    // 检查是否是周末
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return false;
    }
    // 检查是否是特殊日期（如临时休市）
    if (_specialDays.containsKey(date)) return false;
    // 检查是否是年度假日
    if (_yearlyHolidays[date.year]?.contains(date) ?? false) return false;

    return true;
  }

  // 判断当前时间是否是交易时间
  bool isTradingTime() {
    final now = DateTime.now();
    if (!isTradingDay(now)) {
      return false;
    }
    // 检查时间是否在交易时段内（例如美股交易时间：09:30-16:00 ET）
    final time = TimeOfDay.fromDateTime(now);
    final marketOpen = TimeOfDay(hour: 9, minute: 30);
    final marketClose = TimeOfDay(hour: 15, minute: 0);
    // 更清晰的时间比较逻辑
    final isAfterOpen =
        time.hour > marketOpen.hour ||
        (time.hour == marketOpen.hour && time.minute >= marketOpen.minute);

    final isBeforeClose =
        time.hour < marketClose.hour ||
        (time.hour == marketClose.hour && time.minute < marketClose.minute);

    return isAfterOpen && isBeforeClose;
  }

  /// 判断过去第N天是否为交易日 (n=1表示昨天，n=2表示前天...)
  bool isTradingDayAgo(int daysAgo) {
    assert(daysAgo > 0, 'daysAgo必须为正整数');
    final targetDate = DateTime.now().subtract(Duration(days: daysAgo));
    return isTradingDay(targetDate);
  }

  String lastTradingDay([DateTime? currentDate]) {
    final date = currentDate ?? DateTime.now();
    DateTime lastTradingDay = _getPreviousWorkday(date);

    // 这里可以添加节假日判断逻辑
    lastTradingDay = _skipHolidays(lastTradingDay);

    return _formatDate(lastTradingDay);
  }

  /// 获取前一个工作日（跳过周末）
  DateTime _getPreviousWorkday(DateTime date) {
    DateTime previousDay = date.subtract(const Duration(days: 1));

    // 循环直到找到工作日（周一到周五）
    while (previousDay.weekday == DateTime.saturday || previousDay.weekday == DateTime.sunday) {
      previousDay = previousDay.subtract(const Duration(days: 1));
    }

    return previousDay;
  }

  String currentTradingDay() {
    final today = DateTime.now();
    return _formatDate(today);
  }

  // 计算两个日期之间的交易日天数
  int countTradingDays(DateTime start, DateTime end) {
    int count = 0;
    DateTime current = start.copyWith(); // 避免修改原日期

    // 确保 start <= end
    if (start.isAfter(end)) {
      throw ArgumentError('Start date must be before end date');
    }

    // 遍历每一天
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (isTradingDay(current)) {
        count++;
      }
      current = current.add(const Duration(days: 1)); // 下一天
    }
    return count;
  }

  /// 跳过节假日（需要维护节假日列表）
  DateTime _skipHolidays(DateTime date) {
    // 示例节假日列表 - 实际应用中应该从数据库或API获取
    DateTime result = date;
    while ((_yearlyHolidays[date.year]?.contains(date) ?? false) ||
        result.weekday == DateTime.saturday ||
        result.weekday == DateTime.sunday) {
      result = result.subtract(const Duration(days: 1));
    }

    return result;
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // 获取下一个交易日
  DateTime nextTradingDay(DateTime date, {int lookAhead = 30}) {
    for (int i = 1; i <= lookAhead; i++) {
      final nextDay = date.add(Duration(days: i));
      if (isTradingDay(nextDay)) return nextDay;
    }
    throw Exception('No trading day found in next $lookAhead days');
  }
}
