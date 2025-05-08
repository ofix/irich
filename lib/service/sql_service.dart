import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SqlService {
  static const _dbName = 'data/irich.db';
  static const _dbVersion = 1;
  static const _sqlFile = 'lib/runtime/data/irich.sql';

  static Database? _database;

  SqlService._privateConstructor();
  static final SqlService instance = SqlService._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // 获取应用文档目录
    String appDir = "";
    if (Platform.isWindows) {
      appDir = Platform.resolvedExecutable;
    } else {
      appDir = (await getApplicationDocumentsDirectory()).path;
    }
    String path = join(appDir, _dbName);

    // 检查数据库是否已存在
    bool dbExists = await File(path).exists();

    // 打开或创建数据库
    Database db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // 如果数据库不存在，执行SQL初始化
    if (!dbExists) {
      await _executeSqlScript(db);
    }

    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // 数据库首次创建时会执行
    await _executeSqlScript(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 数据库升级逻辑
    if (oldVersion < newVersion) {
      await _executeSqlScript(db);
    }
  }

  Future<void> _executeSqlScript(Database db) async {
    try {
      // 从assets加载SQL文件
      String sql = await rootBundle.loadString(_sqlFile);

      // 分割SQL语句（以分号结尾）
      List<String> statements = sql.split(';');

      // 执行每个SQL语句
      for (String statement in statements) {
        String trimmed = statement.trim();
        if (trimmed.isNotEmpty) {
          await db.execute(trimmed);
        }
      }
    } catch (e) {
      debugPrint('Error executing SQL script: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /////////////////////////////// DAO 操作 ///////////////////////////////////////

  /// 插入数据表
  /// [table] 表名
  /// [row] 数据行
  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert(table, row);
  }

  /// 查询数据表
  /// [table] 表名
  /// [distinct] 是否去重
  /// [columns] 列名
  /// [where] 条件语句
  /// [whereArgs] 条件参数
  /// [groupBy] 分组
  /// [having] 分组过滤条件
  /// [orderBy] 排序
  /// [limit] 返回条目
  /// [offset] 偏移位置
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy = 'desc',
    int? limit = 0,
    int? offset = 100,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// 更新数据表
  /// [table] 表名
  /// [values] 数据行
  /// [where] 更新条件
  /// [whereArgs] 更新条件数值
  /// [conflictAlgorithm] 冲突算法
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    Database db = await database;
    return await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// 原始更新SQL语句
  /// [sql] 更新SQL语句
  /// [arguments] 更新SQL语句参数值
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async {
    Database db = await database;
    return await db.rawUpdate(sql, arguments);
  }

  /// 删除数据
  /// [table] 表名
  /// [where] 条件语句
  /// [whereArgs] 条件语句参数
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    Database db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// 批量插入
  /// [table] 表名
  /// [rows] 数据行
  /// [conflict] 冲突策略
  Future<void> batchInsert(
    String table,
    List<Map<String, dynamic>> rows, {
    ConflictAlgorithm conflict = ConflictAlgorithm.replace,
  }) async {
    if (rows.isEmpty) return;
    final db = await database;

    final columnNames = rows.first.keys.join(',');
    final placeholders = List.filled(rows.first.length, '?').join(',');

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var row in rows) {
        batch.rawInsert('''
          INSERT OR ${conflict.name} INTO $table 
          ($columnNames) 
          VALUES ($placeholders)
          ''', row.values.toList());
      }
      await batch.commit(noResult: true);
    });
  }
}
