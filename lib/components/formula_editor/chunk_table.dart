// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/formula_editor/chunk_table.dart
// Purpose:     chunk table for formula editor
// Author:      songhuabiao
// Created:     2025-06-23 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';
import 'dart:math';

enum ChunkOrigin { original, add }

class Chunk {
  final ChunkOrigin source; // "original" 或 "add"
  int start; // 在源文本中的起始位置
  int length; // 片段长度

  Chunk(this.source, this.start, this.length);

  @override
  String toString() => 'Chunk($source, $start, $length)';
}

class ChunkTable {
  String original; // 原始文本（只读）
  String addBuffer = ""; // 新增文本缓冲区
  List<Chunk> chunks = []; // 片段表
  final List<List<Chunk>> _history = []; // 操作历史（用于撤销）

  ChunkTable(this.original) {
    // 初始化时，整个文本作为一个原始片段
    chunks.add(Chunk(ChunkOrigin.original, 0, original.length));
  }

  void insert(int offset, String text) {
    if (text.isEmpty) return;

    // 1. 将新文本追加到 addBuffer
    final addStart = addBuffer.length;
    addBuffer += text;

    // 2. 保存当前状态到历史（用于撤销）
    _history.add(List<Chunk>.from(chunks));

    // 3. 查找 offset 对应的 Chunk
    int chunkIndex = 0;
    int currentPos = 0;
    while (chunkIndex < chunks.length) {
      final chunk = chunks[chunkIndex];
      if (currentPos + chunk.length > offset) break;
      currentPos += chunk.length;
      chunkIndex++;
    }

    // 4. 分裂目标 Chunk
    if (chunkIndex < chunks.length) {
      final chunk = chunks[chunkIndex];
      final splitPos = offset - currentPos;

      // 分裂为 [left, new, right]
      final left = Chunk(chunk.source, chunk.start, splitPos);
      final newChunk = Chunk(ChunkOrigin.add, addStart, text.length);
      final right = Chunk(chunk.source, chunk.start + splitPos, chunk.length - splitPos);

      chunks.replaceRange(chunkIndex, chunkIndex + 1, [left, newChunk, right]);
    } else {
      // 在末尾插入
      chunks.add(Chunk(ChunkOrigin.add, addStart, text.length));
    }
  }

  void delete(int offset, int length) {
    if (length <= 0) return;

    // 1. 保存当前状态到历史
    _history.add(List<Chunk>.from(chunks));

    int currentPos = 0;
    int remainingLength = length;

    // 2. 遍历找到受影响的 Chunks
    for (int i = 0; i < chunks.length && remainingLength > 0; i++) {
      final chunk = chunks[i];
      if (currentPos + chunk.length <= offset) {
        currentPos += chunk.length;
        continue;
      }

      // 计算删除范围在当前 Chunk 内的部分
      final startInChunk = max(0, offset - currentPos);
      final endInChunk = min(chunk.length, startInChunk + remainingLength);
      final deleteLength = endInChunk - startInChunk;

      // 3. 分裂或缩短 Chunk
      if (deleteLength == chunk.length) {
        // 整个 Chunk 被删除
        chunks.removeAt(i);
        i--; // 调整索引
      } else if (startInChunk == 0) {
        // 删除开头部分
        chunk.start += deleteLength;
        chunk.length -= deleteLength;
      } else if (endInChunk == chunk.length) {
        // 删除末尾部分
        chunk.length = startInChunk;
      } else {
        // 删除中间部分，分裂为两个 Chunk
        final left = Chunk(chunk.source, chunk.start, startInChunk);
        final right = Chunk(chunk.source, chunk.start + endInChunk, chunk.length - endInChunk);
        chunks.replaceRange(i, i + 1, [left, right]);
      }

      remainingLength -= deleteLength;
      currentPos += chunk.length;
    }
  }

  String get text {
    final buffer = StringBuffer();
    for (final piece in chunks) {
      final source = piece.source == "original" ? original : addBuffer;
      buffer.write(source.substring(piece.start, piece.start + piece.length));
    }
    return buffer.toString();
  }

  void undo() {
    if (_history.isEmpty) return;
    chunks = _history.removeLast();
  }
}

class RichDoc {
  String userInput = ""; // 用户输入的文本
  ChunkTable chunkTable = ChunkTable("");
  int cursorPos = 0; // 光标位置
  int editStart = 0; // 编辑起始位置
  int visibleBeginChunk = 0;
  int visbileEndChunk = 10;
  int visibleBeginLine = 0; // 编辑控件可见区域起始行
  int visibleEndLine = 0; // 编辑控件可见区域结束行
  double lineHeight = 16; // 假设每行高度为16像素
  late Timer _timer;

  RichDoc() {
    cursorPos = 0;
    editStart = 0;
    visibleBeginLine = 0;
    visibleEndLine = 10; // 假设可见区域为10行
    _timer = Timer(Duration(milliseconds: 300), () {
      if (userInput == "") return;
      chunkTable.insert(editStart, userInput);
      userInput = "";
    });
  }

  // 鼠标向上滚动
  void scrollUp() {
    if (visibleBeginLine > 0) {
      visibleBeginLine--;
      visibleEndLine--;
    }
  }

  String getLine(int lineNo) {
    return "";
  }

  void insertWord(String word) {
    if (word.isEmpty) return;
    userInput += word;
  }

  void insertChar() {
    if (userInput.isEmpty) return;

    // 如果有未提交的输入，先提交
    if (_timer.isActive) {
      _timer.cancel();
      chunkTable.insert(editStart, userInput);
      userInput = "";
    }

    // 插入新字符
    chunkTable.insert(editStart, userInput);
    cursorPos += userInput.length;
    editStart += userInput.length;
    userInput = "";

    // 重置计时器
    _timer = Timer(Duration(milliseconds: 300), () {
      if (userInput == "") return;
      chunkTable.insert(editStart, userInput);
      userInput = "";
    });
  }

  void setCursorPosition(int row, int column) {}

  void deleteChar() {
    if (cursorPos > 0) {
      cursorPos--;
      editStart--;
      chunkTable.delete(editStart, 1);
    }
  }

  // 鼠标向下滚动
  void scollDown() {
    if (visibleEndLine < chunkTable.chunks.length) {
      visibleBeginLine++;
      visibleEndLine++;
    }
  }
}
