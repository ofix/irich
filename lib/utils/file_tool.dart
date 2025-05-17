// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/utils/file_tool.dart
// Purpose:     file tool util class
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:irich/service/trading_calendar.dart';
import 'package:irich/utils/date_time.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileTool {
  /// Gets the modified time of a file in 'YYYY-MM-DD HH:mm:ss' format
  ///
  /// [path] The file path
  ///
  /// Returns: Formatted timestamp string, or empty string on failure
  static Future<String> getFileModifiedTime(String path) async {
    try {
      final file = File(path);
      final stat = await file.stat();
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(stat.modified);
    } catch (e) {
      return '';
    }
  }

  /// 保存文件内容（自动创建不存在的目录）
  ///
  /// [filePath] 文件路径
  /// [content] 要写入的内容
  ///
  /// 返回: 是否保存成功
  static Future<bool> saveFile(String filePath, String content) async {
    try {
      final file = File(filePath);

      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      await file.writeAsString(content);
      return true;
    } catch (e) {
      print('保存文件失败: $e');
      return false;
    }
  }

  static Future<String> getExecutableDir() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // 移动端返回应用沙盒目录
      return (await getApplicationDocumentsDirectory()).parent.path;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 桌面端返回可执行文件所在目录
      return Platform.resolvedExecutable.replaceAll(Platform.executable, '');
    }
    return "";
  }

  static Future<bool> isFileExist(String path) async {
    final file = File(path);
    return await file.exists(); // 返回布尔值
  }

  /// Loads entire file into memory as a String
  ///
  /// [filePath] Path to the file
  ///
  /// Returns: File content as String, or empty string if failed
  static Future<String> loadFile(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      return String.fromCharCodes(bytes);
    } catch (e) {
      print('Error loading file: $e');
      return '';
    }
  }

  /// Alternative version that returns raw bytes
  static Future<Uint8List> loadFileAsBytes(String filePath) async {
    try {
      return await File(filePath).readAsBytes();
    } catch (e) {
      print('Error loading file: $e');
      return Uint8List(0);
    }
  }

  /// Reads the last line of a file efficiently
  ///
  /// [filename] Path to the file
  ///
  /// Returns: A tuple containing (success status, last line content)
  static Future<(bool, String)> getLastLineOfFile(String filename) async {
    try {
      final file = File(filename);
      final length = await file.length();
      const chunkSize = 512; // Same buffer size as C++ version

      // Read last chunk of the file
      final startPos = length > chunkSize ? length - chunkSize : 0;
      final randomAccessFile = await file.open();
      await randomAccessFile.setPosition(startPos);
      final buffer = await randomAccessFile.read(chunkSize);
      await randomAccessFile.close();

      // Process buffer to find last line
      int endPos = buffer.length - 1;
      while (endPos >= 0 &&
          (buffer[endPos] == '\n'.codeUnitAt(0) || buffer[endPos] == '\r'.codeUnitAt(0))) {
        endPos--;
      }

      int startPosInBuffer = 0;
      for (int i = endPos; i >= 0; i--) {
        if (buffer[i] == '\n'.codeUnitAt(0)) {
          startPosInBuffer = i + 1;
          break;
        }
      }

      final lastLine = String.fromCharCodes(buffer.sublist(startPosInBuffer, endPos + 1));

      return (true, lastLine);
    } catch (e) {
      return (false, "");
    }
  }

  /// 检查每日需要更新的本地数据文件是否过期
  static Future<bool> isDailyFileExpired(String filePath) async {
    // 获取本地行情数据文件修改时间
    String localQuoteFileModifiedTime = await FileTool.getFileModifiedTime(filePath);
    // String today = now("%Y-%m-%d");
    String nowTime = now("%Y-%m-%d %H:%M:%S");
    final calendar = TradingCalendar();
    if (calendar.isTradingDay(DateTime.now())) {
      // 如果当天是交易日
      // String lastTradeDay = getNearestTradeDay(-1);
      // 上一个交易日的收盘时间
      String currentTradeDay = calendar.lastTradingDay();
      String currentTradeOpenTime = "$currentTradeDay 09:30:00"; // 当天开盘时间
      String currentTradeCloseTime = "$currentTradeDay 15:00:00"; // 当天收盘时间
      if (compareTime(localQuoteFileModifiedTime, currentTradeCloseTime) > 0 && // 文件时间大于昨天收盘时间
          compareTime(nowTime, currentTradeOpenTime) < 0 && // 当前时间未开盘
          compareTime(localQuoteFileModifiedTime, currentTradeOpenTime) <
              0 // 文件时间小于今天开盘时间
              ) {
        return false;
      }

      if (compareTime(localQuoteFileModifiedTime, currentTradeCloseTime) > 0) {
        // 文件时间大于当天收盘时间
        return false;
      }

      return true;
    } else {
      String lastTradeDay = calendar.lastTradingDay();
      String lastTradeCloseTime = "$lastTradeDay 15:00:00";
      // 检查文件修改时间是否 > 最近交易日收盘时间
      if (compareTime(localQuoteFileModifiedTime, lastTradeCloseTime) > 0) {
        return false;
      }
      return true;
    }
  }

  static Future<String> getRuntimeDir() async {
    final dir = await getApplicationDocumentsDirectory(); // 或 getApplicationSupportDirectory()
    return dir.path;
  }

  static Future<File> copyFileToAppDir(String assetPath) async {
    // 获取应用可写目录（不同平台路径不同）
    final appDir = await getApplicationDocumentsDirectory();
    final targetFile = File('${appDir.path}/${assetPath.split('/').last}');

    // 如果文件已存在，直接返回
    if (await targetFile.exists()) return targetFile;

    // 从 assets 复制到可写目录
    final byteData = await rootBundle.load(assetPath);
    await targetFile.writeAsBytes(byteData.buffer.asUint8List());
    return targetFile;
  }

  static Future<String> getAppRootDir() async {
    String appRootDir = "";
    if (Platform.isWindows) {
      String binPath = Platform.resolvedExecutable;
      appRootDir = File(binPath).parent.path;
    } else {
      appRootDir = (await getApplicationDocumentsDirectory()).path;
    }
    return appRootDir;
  }

  // 拷贝文件到目录
  static Future<void> installDir(String srcDir) async {
    try {
      // 1. 获取应用文档目录
      final String targetRoot = await getAppRootDir();

      // 2. 获取AssetManifest.json内容
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = jsonDecode(manifestContent);

      // 3. 筛选出lib/runtime目录下的所有文件
      final runtimeFiles = manifestMap.keys.where((String key) => key.startsWith(srcDir)).toList();

      if (runtimeFiles.isEmpty) {
        debugPrint('No files found in $srcDir');
        return;
      }

      // 4. 遍历并拷贝每个文件
      for (String assetPath in runtimeFiles) {
        // 计算相对路径（移除前面的"lib/runtime/"部分）
        final relativePath = assetPath.substring(srcDir.length + 1);

        // 构建目标文件路径
        final String destinationPath = p.join(targetRoot, relativePath);
        final File destinationFile = File(destinationPath);

        if (await destinationFile.exists()) {
          debugPrint("目录文件已经存在，${destinationFile.path}");
          continue;
        }

        // 确保目标目录存在
        await destinationFile.parent.create(recursive: true);

        // 读取asset文件内容
        final ByteData data = await rootBundle.load(assetPath);
        final Uint8List bytes = data.buffer.asUint8List();

        // 写入目标文件
        await destinationFile.writeAsBytes(bytes);
      }
    } catch (e) {
      debugPrint('Error copying runtime files: $e');
      rethrow;
    }
  }
}
