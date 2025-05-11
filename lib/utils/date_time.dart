// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/utils/date_time.dart
// Purpose:     date time util classes
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:intl/intl.dart';

/// Calculates a date relative to today
///
/// [ndays] Number of days from today (positive for future, negative for past)
///
/// Returns: Date in "YYYY-MM-DD" format (e.g. "2024-07-25")
String getDayFromNow(int ndays) {
  // Calculate target date
  final targetDate = DateTime.now().add(Duration(days: ndays));

  // Format as YYYY-MM-DD
  final formattedDate = DateFormat('yyyy-MM-dd').format(targetDate);

  return formattedDate;
}

/// Checks if current time is between [startTime] and [endTime] in "HH:mm" format
///
/// [startTime] Start time (e.g. "09:00")
/// [endTime] End time (e.g. "09:30")
///
/// Returns:
///   true if current time is within the specified range (inclusive)
///   false if outside range or invalid format
bool betweenTimePeriod(String startTime, String endTime) {
  try {
    // Get current time in local timezone
    final now = DateTime.now();
    final currentTime = DateFormat('HH:mm').format(now);

    // Compare as strings (works because format is fixed-length)
    return currentTime.compareTo(startTime) >= 0 && currentTime.compareTo(endTime) <= 0;
  } catch (e) {
    // Handle any format errors
    return false;
  }
}

/// Calculates the number of seconds between two timestamps in "YYYY-MM-DD HH:mm:ss" format
///
/// [startTime] 开始时间格式: "2024-06-20 09:00:12")
/// [endTime] 结束时间格式: "2024-06-20 09:30:00")
///
/// Returns:
///   Number of seconds between timestamps (positive if endTime > startTime)
///   -1 if either timestamp format is invalid
int diffSeconds(String startTime, String endTime) {
  try {
    // Parse timestamps (using intl package for strict format validation)
    final format = DateFormat('yyyy-MM-dd HH:mm:ss');
    final startDate = format.parseStrict(startTime);
    final endDate = format.parseStrict(endTime);

    // Calculate difference in seconds
    return endDate.difference(startDate).inSeconds;
  } catch (e) {
    // Handle parsing errors (invalid format)
    return -1;
  }
}

/// Calculates the number of days between two dates in "YYYY-MM-DD" format
///
/// [startDay] 开始时间格式: "YYYY-MM-DD" (比如, "2024-06-20")
/// [endDay] 结束时间格式 "YYYY-MM-DD" (比如, "2024-06-21")
///
/// Returns:
///   Number of days between dates (positive if endDay > startDay)
///   -1 if either date format is invalid
int diffDays(String startDay, String endDay) {
  try {
    // Parse dates (automatically handles YYYY-MM-DD format)
    final startDate = DateTime.parse(startDay);
    final endDate = DateTime.parse(endDay);

    // Calculate difference in days
    final difference = endDate.difference(startDate);
    return difference.inDays;
  } catch (e) {
    return -1;
  }
}

/// Formats current time according to specified format
///
/// [format] Format string (e.g. "%Y-%m-%d %H:%M:%S")
///
/// Returns: Formatted date/time string
String now(String format) {
  // Convert C-style format to Dart's DateFormat patterns
  final dartFormat = format
      .replaceAll('%Y', 'yyyy')
      .replaceAll('%m', 'MM')
      .replaceAll('%d', 'dd')
      .replaceAll('%H', 'HH')
      .replaceAll('%M', 'mm')
      .replaceAll('%S', 'ss');

  return DateFormat(dartFormat).format(DateTime.now());
}

/// 比较时间大小，格式 YYYY-mm-dd HH:mm:ss 标准格式
///
/// Returns:
///   0: time1 == time2
///  -1: time1 < time2
///   1: time1 > time2
int compareTime(String time1, String time2) {
  try {
    final format = DateFormat('yyyy-MM-dd HH:mm:ss');
    final dt1 = format.parseStrict(time1);
    final dt2 = format.parseStrict(time2);

    return dt1.compareTo(dt2);
  } catch (e) {
    return -1;
  }
}
