// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/sql_service.dart
// Purpose:     sql service for access SQLite database
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:irich/global/backtest.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/utils/file_tool.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
    String appDir = await FileTool.getAppRootDir();
    String path = join(appDir, _dbName);

    // 检查数据库是否已存在
    bool dbExists = await File(path).exists();

    // 如果是桌面端（非Web、非移动端），初始化 FFI
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      databaseFactory = databaseFactoryFfi;
    }
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

  Future<void> _createDb(Database db, int version) async {
    // 创建股票表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stocks (
        stock_code TEXT PRIMARY KEY,
        stock_name TEXT,
        industry TEXT
      )
    ''');

    // 创建财务数据表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS financial_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stock_code TEXT,
        report_date TEXT,
        total_assets REAL,
        total_liabilities REAL,
        shareholders_equity REAL,
        net_profit REAL,
        operating_revenue REAL,
        operating_profit REAL,
        cash_flow_from_operations REAL,
        FOREIGN KEY (stock_code) REFERENCES stocks (stock_code)
      )
    ''');

    // 创建市场数据表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS market_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stock_code TEXT,
        trade_date TEXT,
        open_price REAL,
        high_price REAL,
        low_price REAL,
        close_price REAL,
        volume REAL,
        FOREIGN KEY (stock_code) REFERENCES stocks (stock_code)
      )
    ''');

    // 创建索引以提高查询性能
    await db.execute('CREATE INDEX IF NOT EXISTS idx_stocks_code ON stocks(stock_code)');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_financial_code_date ON financial_data(stock_code, report_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_market_code_date ON market_data(stock_code, trade_date)',
    );
  }

  // 获取单个股票的财务数据
  Future<List<FinancialData>> getFinancialData(String stockCode) async {
    final db = await database;
    final result = await db.query(
      'financial_data',
      where: 'stock_code = ?',
      whereArgs: [stockCode],
      orderBy: 'report_date DESC',
    );
    return result.map((map) => FinancialData.fromMap(map)).toList();
  }

  // 获取单个股票的市场数据
  Future<List<MarketData>> getMarketData(
    String stockCode, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = 'stock_code = ?';
    List<dynamic> whereArgs = [stockCode];

    if (startDate != null && endDate != null) {
      whereClause += ' AND trade_date BETWEEN ? AND ?';
      whereArgs.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
    }

    final result = await db.query(
      'market_data',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'trade_date ASC',
    );
    return result.map((map) => MarketData.fromMap(map)).toList();
  }

  // 批量插入财务数据
  Future<void> insertFinancialData(List<FinancialData> dataList) async {
    final db = await database;
    final batch = db.batch();

    for (final data in dataList) {
      batch.insert('financial_data', {
        'stock_code': data.stockCode,
        'report_date': data.reportDate.toIso8601String(),
        'total_assets': data.totalAssets,
        'total_liabilities': data.totalLiabilities,
        'shareholders_equity': data.shareholdersEquity,
        'net_profit': data.netProfit,
        'operating_revenue': data.operatingRevenue,
        'operating_profit': data.operatingProfit,
        'cash_flow_from_operations': data.cashFlowFromOperations,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  // 批量插入市场数据
  Future<void> insertMarketData(List<MarketData> dataList) async {
    final db = await database;
    final batch = db.batch();

    for (final data in dataList) {
      batch.insert('market_data', {
        'stock_code': data.stockCode,
        'trade_date': data.date.toIso8601String(),
        'open_price': data.open,
        'high_price': data.high,
        'low_price': data.low,
        'close_price': data.close,
        'volume': data.volume,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  // 添加财务指标
  Future<int> addShareFinance(ShareFinance finance) async {
    final db = await database;
    return await db.insert(
      'share_finance',
      _financeToMap(finance),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 批量添加财务指标
  Future<void> addBatchShareFinance(List<ShareFinance> finances) async {
    if (finances.isEmpty) return;

    final db = await database;
    final batch = db.batch();

    for (final finance in finances) {
      batch.insert(
        'share_finance',
        _financeToMap(finance),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // 更新财务指标
  Future<int> udpateShareFinance(ShareFinance finance) async {
    final db = await database;
    return await db.update(
      'share_finance',
      _financeToMap(finance),
      where: 'code = ? AND year = ? AND quarter = ?',
      whereArgs: [finance.code, finance.year, finance.quarter],
    );
  }

  // 删除财务指标
  Future<int> deleteShareFinance(String code, int year, int quarter) async {
    final db = await database;
    return await db.delete(
      'share_finance',
      where: 'code = ? AND year = ? AND quarter = ?',
      whereArgs: [code, year, quarter],
    );
  }

  // 删除某只股票的所有财务数据
  Future<int> deleteShareAllFinance(String code) async {
    final db = await database;
    return await db.delete('share_finance', where: 'code = ?', whereArgs: [code]);
  }

  // 查询单个财务指标
  Future<ShareFinance?> getShareFinance(String code, int year, int quarter) async {
    final db = await database;
    final result = await db.query(
      'share_finance',
      where: 'code = ? AND year = ? AND quarter = ?',
      whereArgs: [code, year, quarter],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return _mapToFinance(result.first);
  }

  // 查询某只股票的所有财务指标
  Future<List<ShareFinance>> getAllShareFinanceByCode(String code, {String? orderBy}) async {
    final db = await database;
    final result = await db.query(
      'share_finance',
      where: 'code = ?',
      whereArgs: [code],
      orderBy: orderBy ?? 'year DESC, quarter DESC',
    );

    return result.map((map) => _mapToFinance(map)).toList();
  }

  // 查询某只股票指定年份的所有季度财务指标
  Future<List<ShareFinance>> getShareFinanceByYear(String code, int year) async {
    final db = await database;
    final result = await db.query(
      'share_finance',
      where: 'code = ? AND year = ?',
      whereArgs: [code, year],
      orderBy: 'quarter DESC',
    );

    return result.map((map) => _mapToFinance(map)).toList();
  }

  // 查询最新财务指标
  Future<ShareFinance?> getLatestShareFinanceByCode(String code) async {
    final db = await database;
    final result = await db.query(
      'share_finance',
      where: 'code = ?',
      whereArgs: [code],
      orderBy: 'year DESC, quarter DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return _mapToFinance(result.first);
  }

  // 查询所有股票的财务指标（分页）
  Future<List<ShareFinance>> getAllShareFinance({
    int limit = 100,
    int offset = 0,
    String? orderBy,
  }) async {
    final db = await database;
    final result = await db.query(
      'share_finance',
      limit: limit,
      offset: offset,
      orderBy: orderBy ?? 'code ASC, year DESC, quarter DESC',
    );

    return result.map((map) => _mapToFinance(map)).toList();
  }

  // 将ShareFinance对象转换为Map
  Map<String, dynamic> _financeToMap(ShareFinance finance) {
    return {
      'code': finance.code,
      'year': finance.year,
      'quarter': finance.quarter,
      'main_business_income': finance.mainBusinessIncome,
      'main_business_profit': finance.mainBusinessProfit,
      'total_assets': finance.totalAssets,
      'current_assets': finance.currentAssets,
      'fixed_assets': finance.fixedAssets,
      'intangible_assets': finance.intangibleAssets,
      'long_term_investment': finance.longTermInvestment,
      'current_liabilities': finance.currentLiabilities,
      'long_term_liabilities': finance.longTermLiabilities,
      'capital_reserve': finance.capitalReserve,
      'per_share_reserve': finance.perShareReserve,
      'shareholder_equity': finance.shareholderEquity,
      'per_share_net_assets': finance.perShareNetAssets,
      'operating_income': finance.operatingIncome,
      'net_profit': finance.netProfit,
      'undistributed_profit': finance.undistributedProfit,
      'per_share_undistributed_profit': finance.perShareUndistributedProfit,
      'per_share_earnings': finance.perShareEarnings,
      'per_share_cash_flow': finance.perShareCashFlow,
      'per_share_operating_cash_flow': finance.perShareOperatingCashFlow,

      // 成长能力指标
      'net_profit_growth_rate': finance.netProfitGrowthRate,
      'operating_income_growth_rate': finance.operatingIncomeGrowthRate,
      'total_assets_growth_rate': finance.totalAssetsGrowthRate,
      'shareholder_equity_growth_rate': finance.shareholderEquityGrowthRate,

      // 现金流指标
      'operating_cash_flow': finance.operatingCashFlow,
      'investment_cash_flow': finance.investmentCashFlow,
      'financing_cash_flow': finance.financingCashFlow,
      'cash_increase': finance.cashIncrease,
      'per_share_operating_cash_flow_net': finance.perShareOperatingCashFlowNet,
      'per_share_cash_increase': finance.perShareCashIncrease,
      'per_share_earnings_after_non_recurring': finance.perShareEarningsAfterNonRecurring,

      // 自动计算指标
      'net_profit_rate': finance.netProfitRate,
      'gross_profit_rate': finance.grossProfitRate,
      'roe': finance.roe,
      'debt_ratio': finance.debtRatio,
      'current_ratio': finance.currentRatio,
      'quick_ratio': finance.quickRatio,
    };
  }

  // 将Map转换为ShareFinance对象
  ShareFinance _mapToFinance(Map<String, dynamic> map) {
    return ShareFinance(
      code: map['code'] ?? '',
      year: map['year'] ?? 0,
      quarter: map['quarter'] ?? 0,
      mainBusinessIncome: map['main_business_income']?.toDouble() ?? 0.0,
      mainBusinessProfit: map['main_business_profit']?.toDouble() ?? 0.0,
      totalAssets: map['total_assets']?.toDouble() ?? 0.0,
      currentAssets: map['current_assets']?.toDouble() ?? 0.0,
      fixedAssets: map['fixed_assets']?.toDouble() ?? 0.0,
      intangibleAssets: map['intangible_assets']?.toDouble() ?? 0.0,
      longTermInvestment: map['long_term_investment']?.toDouble() ?? 0.0,
      currentLiabilities: map['current_liabilities']?.toDouble() ?? 0.0,
      longTermLiabilities: map['long_term_liabilities']?.toDouble() ?? 0.0,
      capitalReserve: map['capital_reserve']?.toDouble() ?? 0.0,
      perShareReserve: map['per_share_reserve']?.toDouble() ?? 0.0,
      shareholderEquity: map['shareholder_equity']?.toDouble() ?? 0.0,
      perShareNetAssets: map['per_share_net_assets']?.toDouble() ?? 0.0,
      operatingIncome: map['operating_income']?.toDouble() ?? 0.0,
      netProfit: map['net_profit']?.toDouble() ?? 0.0,
      undistributedProfit: map['undistributed_profit']?.toDouble() ?? 0.0,
      perShareUndistributedProfit: map['per_share_undistributed_profit']?.toDouble() ?? 0.0,
      perShareEarnings: map['per_share_earnings']?.toDouble() ?? 0.0,
      perShareCashFlow: map['per_share_cash_flow']?.toDouble() ?? 0.0,
      perShareOperatingCashFlow: map['per_share_operating_cash_flow']?.toDouble() ?? 0.0,

      // 成长能力指标
      netProfitGrowthRate: map['net_profit_growth_rate']?.toDouble() ?? 0.0,
      operatingIncomeGrowthRate: map['operating_income_growth_rate']?.toDouble() ?? 0.0,
      totalAssetsGrowthRate: map['total_assets_growth_rate']?.toDouble() ?? 0.0,
      shareholderEquityGrowthRate: map['shareholder_equity_growth_rate']?.toDouble() ?? 0.0,

      // 现金流指标
      operatingCashFlow: map['operating_cash_flow']?.toDouble() ?? 0.0,
      investmentCashFlow: map['investment_cash_flow']?.toDouble() ?? 0.0,
      financingCashFlow: map['financing_cash_flow']?.toDouble() ?? 0.0,
      cashIncrease: map['cash_increase']?.toDouble() ?? 0.0,
      perShareOperatingCashFlowNet: map['per_share_operating_cash_flow_net']?.toDouble() ?? 0.0,
      perShareCashIncrease: map['per_share_cash_increase']?.toDouble() ?? 0.0,
      perShareEarningsAfterNonRecurring:
          map['per_share_earnings_after_non_recurring']?.toDouble() ?? 0.0,

      // 自动计算指标（如果数据库中有值则使用，否则会自动计算）
      netProfitRate: map['net_profit_rate']?.toDouble(),
      grossProfitRate: map['gross_profit_rate']?.toDouble(),
      roe: map['roe']?.toDouble(),
      debtRatio: map['debt_ratio']?.toDouble(),
      currentRatio: map['current_ratio']?.toDouble(),
      quickRatio: map['quick_ratio']?.toDouble(),
    );
  }
}
