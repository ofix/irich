// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/global/config.dart
// Purpose:     global config class
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/utils/file_tool.dart';
import 'package:path/path.dart' as p;

class Config {
  // 地域板块=>个股映射文件路径
  static Future<String> get pathMapFileProvince async {
    String appRootDir = await FileTool.getAppRootDir();
    return p.join(appRootDir, 'data', 'province.json');
  }

  // 行业板块=>个股映射文件路径
  static Future<String> get pathMapFileIndustry async {
    String appRootDir = await FileTool.getAppRootDir();
    return p.join(appRootDir, 'data', 'industry.json');
  }

  // 概念板块=>个股映射文件路径
  static Future<String> get pathMapFileConcept async {
    String appRootDir = await FileTool.getAppRootDir();
    return p.join(appRootDir, 'data', 'concept.json');
  }

  // 行情数据文件路径
  static Future<String> get pathDataFileQuote async {
    String appRootDir = await FileTool.getAppRootDir();
    return p.join(appRootDir, 'data', 'quote.json');
  }

  // 节假日数据文件路径
  static Future<String> get pathDataFileHoliday async {
    String appRootDir = await FileTool.getAppRootDir();
    return p.join(appRootDir, 'data', 'holidays.json');
  }

  // 暂停任务文件路径
  static Future<String> get pathTask async {
    String appRootDir = await FileTool.getAppRootDir();
    return p.join(appRootDir, 'tasks');
  }

  // SQLite数据库文件
  static String pathSql = "data/irich.sql";
}
