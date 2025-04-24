// ignore_for_file: avoid_print

import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';

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
          (buffer[endPos] == '\n'.codeUnitAt(0) ||
              buffer[endPos] == '\r'.codeUnitAt(0))) {
        endPos--;
      }

      int startPosInBuffer = 0;
      for (int i = endPos; i >= 0; i--) {
        if (buffer[i] == '\n'.codeUnitAt(0)) {
          startPosInBuffer = i + 1;
          break;
        }
      }

      final lastLine = String.fromCharCodes(
        buffer.sublist(startPosInBuffer, endPos + 1),
      );

      return (true, lastLine);
    } catch (e) {
      return (false, "");
    }
  }
}
