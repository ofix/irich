// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/utils/helper.dart
// Purpose:     money unit helper class
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

class Helper {
  static String richUnit(double num) {
    if (num == 0) {
      return "---"; // 股票停牌没有成交量和成交额
    }

    String result;
    if (num >= 100000000) {
      num /= 100000000;
      result = "${num.toStringAsFixed(2)}亿";
    } else if (num >= 10000) {
      num /= 10000;
      result = "${num.toStringAsFixed(2)}万";
    } else {
      result = num.toInt().toString(); // 直接转换为整数并转为字符串
    }
    return result; // 假设 CN 转换可以直接用 String 返回，或者根据需要实现 CN 函数
  }
}
