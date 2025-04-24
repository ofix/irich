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
    return currentTime.compareTo(startTime) >= 0 && 
           currentTime.compareTo(endTime) <= 0;
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

/// Checks if a given date is a trading day (not weekend or Chinese holiday)
/// [day] Date string in "YYYY-MM-DD" format
/// Returns true if it's a trading day, false otherwise
bool isTradeDay(String day) {
  try {

    final date = DateFormat('yyyy-MM-dd').parseStrict(day);

    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return false;
    }
  
    if (isChineseHoliday(day)) {
      return false;
    }
    
    return true;
  } catch (e) {
    // Handle date parsing errors
    return false;
  }
}

/// @brief  获取最近交易日交易日期，只考虑周末，暂不考虑中国节假日带来的影响
/// [days] 交易日天数，如果是-1，则表示最近交易日的上一个交易日，默认是0，则表示最近交易日或者当天交易日
/// Returns:
///   交易日期 格式 YYYY-mm-dd,比如 2024-03-05
String getNearestTradeDay([int days = 0]) {
  days = days.abs(); // Get absolute value
  DateTime tradeDay = DateTime.now();
  String formatTradeDay = DateFormat('yyyy-MM-dd').format(tradeDay);

  // Count back the specified number of trading days
  while (days > 0) {
    if (tradeDay.weekday != DateTime.sunday &&
        tradeDay.weekday != DateTime.saturday &&
        !isChineseHoliday(formatTradeDay)) {
      days -= 1;
    }
    tradeDay = tradeDay.subtract(const Duration(days: 1));
    formatTradeDay = DateFormat('yyyy-MM-dd').format(tradeDay);
  }

  // If we need the nearest trading day (days == 0)
  if (days == 0) {
    while (tradeDay.weekday == DateTime.sunday ||
        tradeDay.weekday == DateTime.saturday ||
        isChineseHoliday(formatTradeDay)) {
      tradeDay = tradeDay.subtract(const Duration(days: 1));
      formatTradeDay = DateFormat('yyyy-MM-dd').format(tradeDay);
    }
  }

  return formatTradeDay;
}

/// 判断是否是中国节假日
/// [day] 日期格式 YYYY-mm-dd,比如 2024-03-05
/// Returns
///  true: 是节假日
bool isChineseHoliday(String day) {
  final Map<String, bool> holidays = {
    // 2022年1月份
    "2022-01-03": true, // 2022年元旦
    "2022-01-31": true, // 2021年除夕
    // 2022年2月份
    "2022-02-01": true, // 2021年春节
    "2022-02-02": true,
    "2022-02-03": true,
    "2022-02-04": true,
    // 2022年4月份
    "2022-04-04": true, // 2022年清明节
    "2022-04-05": true,
    // 2022年5月份
    "2022-05-02": true, // 2022年劳动节
    "2022-05-03": true,
    "2022-05-04": true,
    // 2022年6月份
    "2022-06-03": true, // 2022年端午节
    // 2022年9月份
    "2022-09-12": true, // 2022年中秋节
    // 2022年10月份
    "2022-10-03": true, // 2022年国庆节
    "2022-10-04": true,
    "2022-10-05": true,
    "2022-10-06": true,
    "2022-10-07": true,
    // 2023年1月份
    "2023-01-02": true, // 2023年元旦
    "2023-01-23": true, // 2022年春节
    "2023-01-24": true,
    "2023-01-25": true,
    "2023-01-26": true,
    "2023-01-27": true,
    // 2023年4月份
    "2023-04-05": true, // 2023年清明节
    // 2023年5月份
    "2023-05-01": true, // 2023年劳动节
    "2023-05-02": true,
    "2023-05-03": true,
    // 2023年6月份
    "2023-06-22": true, // 2023年端午节
    "2023-06-23": true,
    // 2023年9月份
    "2023-09-29": true, // 2023年中秋节
    // 2023年10月份
    "2023-10-02": true, // 2023年国庆节
    "2023-10-03": true,
    "2023-10-04": true,
    "2023-10-05": true,
    "2023-10-06": true,
    // 2024年1月份
    "2024-01-01": true, // 2024年元旦
    // 2024年2月份
    "2024-02-12": true, // 2023年春节
    "2024-02-13": true,
    "2024-02-14": true,
    "2024-02-15": true,
    "2024-02-16": true,
    // 2024年4月份
    "2024-04-04": true, // 2024年清明节
    "2024-04-05": true,
    // 2024年5月份
    "2024-05-01": true, // 2024年劳动节
    "2024-05-02": true,
    "2024-05-03": true,
    // 2024年6月份
    "2024-06-10": true, // 2024年端午节
    "2024-09-16": true,
    "2024-09-17": true,
    "2024-10-01": true,
    "2024-10-02": true,
    "2024-10-03": true,
    "2024-10-04": true,
  };
  if (holidays.containsKey(day)) {
    return true;
  }
  return false;
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
