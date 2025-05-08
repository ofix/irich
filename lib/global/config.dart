import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class Config {
  // 地域板块=>个股映射文件路径
  static Future<String> get pathMapFileProvince async {
    String appDir = "";
    if (Platform.isWindows) {
      appDir = Platform.resolvedExecutable;
    } else {
      appDir = (await getApplicationDocumentsDirectory()).path;
    }
    return p.join(appDir, 'data', 'province.json');
  }

  // 行业板块=>个股映射文件路径
  static Future<String> get pathMapFileIndustry async {
    String appDir = "";
    if (Platform.isWindows) {
      appDir = Platform.resolvedExecutable;
    } else {
      appDir = (await getApplicationDocumentsDirectory()).path;
    }
    return p.join(appDir, 'data', 'industry.json');
  }

  // 概念板块=>个股映射文件路径
  static Future<String> get pathMapFileConcept async {
    String appDir = "";
    if (Platform.isWindows) {
      appDir = Platform.resolvedExecutable;
    } else {
      appDir = (await getApplicationDocumentsDirectory()).path;
    }
    return p.join(appDir, 'data', 'concept.json');
  }

  // 行情数据文件路径
  static Future<String> get pathDataFileQuote async {
    String appDir = "";
    if (Platform.isWindows) {
      appDir = Platform.resolvedExecutable;
    } else {
      appDir = (await getApplicationDocumentsDirectory()).path;
    }
    return p.join(appDir, 'data', 'quote.json');
  }

  // SQLite数据库文件
  static String pathSql = "data/irich.sql";
}
