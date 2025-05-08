import 'package:path_provider/path_provider.dart';

class Config {
  // 地域板块=>个股映射文件路径
  static Future<String> get pathMapFileProvince async {
    final appDir = await getApplicationDocumentsDirectory();
    return "${appDir.path}/data/province.json";
  }

  // 行业板块=>个股映射文件路径
  static Future<String> get pathMapFileIndustry async {
    final appDir = await getApplicationDocumentsDirectory();
    return "${appDir.path}/data/industry.json";
  }

  // 概念板块=>个股映射文件路径
  static Future<String> get pathMapFileConcept async {
    final appDir = await getApplicationDocumentsDirectory();
    return "${appDir.path}/data/concept.json";
  }

  // 行情数据文件路径
  static Future<String> get pathDataFileQuote async {
    final appDir = await getApplicationDocumentsDirectory();
    return "${appDir.path}/data/quote.json";
  }

  // SQLite数据库文件
  static String pathSql = "data/irich.sql";
}
