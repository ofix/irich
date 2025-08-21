// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/utils/file_tool.dart
// Purpose:     file tool util class
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
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
    try {
      // 1. 基础校验
      if (path.trim().isEmpty) return false;
      // 2. 标准化路径（处理./、../等）
      final normalizedPath = p.normalize(path);
      debugPrint(normalizedPath);
      // 3. 直接检查目标路径（不检查父目录）
      final result = await FileSystemEntity.type(normalizedPath).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('路径检查超时: $normalizedPath');
          return FileSystemEntityType.notFound; // 关键修复：返回枚举而非bool
        },
      );
      return result != FileSystemEntityType.notFound;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  /// Loads entire file into memory as a String
  ///
  /// [filePath] Path to the file
  ///
  /// Returns: File content as String, or empty string if failed
  static Future<String> loadFile(String filePath) async {
    try {
      final file = File(filePath);
      final result = await file.readAsString();
      return result;
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

  /// delete the last line of file efficiently
  ///
  /// [filename] Path to the file
  ///
  /// Returns: A tuple containing (success status, last line content)
  static Future<void> removeLastLineOfFile(String filePath, {int chunkSize = 1024}) async {
    final file = File(filePath);
    final raf = await file.open(mode: FileMode.append);

    try {
      int fileSize = await raf.length();
      int pos = fileSize;
      bool foundNewline = false;
      final buffer = List<int>.filled(chunkSize, 0);

      while (pos > 0 && !foundNewline) {
        // 计算当前块的起始位置和大小
        int readSize = (pos >= chunkSize) ? chunkSize : pos;
        pos -= readSize;
        await raf.setPosition(pos);
        await raf.readInto(buffer, 0, readSize);

        // 从后向前搜索换行符，跳过最后几个换行符字符
        for (int i = readSize - 3; i >= 0; i--) {
          if (buffer[i] == 10 || buffer[i] == 13) {
            // 10是\n的ASCII码，13 是\r的ASCII码
            foundNewline = true;
            pos += i + 1; // 定位到换行符后
            break;
          }
        }
      }

      // 截断文件到倒数第二行末尾
      await raf.truncate(pos);
    } finally {
      await raf.close();
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
      String lastTradeDay = calendar.lastTradingDay();
      String currentTradeDay = calendar.currentTradingDay();
      String lastTradeCloseTime = "$lastTradeDay 15:00:00"; // 当天开盘时间
      String currentTradeOpenTime = "$currentTradeDay 09:30:00"; // 当天开盘时间
      String currentTradeCloseTime = "$currentTradeDay 15:00:00"; // 当天收盘时间
      if (compareTime(localQuoteFileModifiedTime, lastTradeCloseTime) > 0 && // 文件时间大于上一次收盘时间
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

  /// 检查每周需要更新的本地数据文件是否过期
  static Future<bool> isWeekFileExpired(String filePath, {int days = 100}) async {
    // 获取本地行情数据文件修改时间
    final file = File(filePath);
    final stat = await file.stat();
    final age = DateTime.now().difference(stat.modified).inDays;
    if (age >= days) {
      return true;
    }
    return false;
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
    return p.normalize(appRootDir);
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
