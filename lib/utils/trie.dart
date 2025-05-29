// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/utils/trie.dart
// Purpose:     trie class for shares
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/widgets.dart';

class TrieNode {
  int depth = 0;
  bool isWord = false;
  final Map<String, TrieNode> children = {};
  final List<String> shareCodeList = [];

  TrieNode([this.depth = 0]);
}

class Trie {
  final TrieNode root = TrieNode();

  void build(List<MapEntry<String, String>> words) {
    for (final word in words) {
      insert(word.key, word.value);
    }
  }

  // 支持中英文混合
  void insert(String chinese, String shareCode) {
    TrieNode node = root;
    for (final letter in chinese.characters) {
      node.children.putIfAbsent(letter, () => TrieNode(node.depth + 1));
      node = node.children[letter]!;
    }
    node.isWord = true;
    node.shareCodeList.add(shareCode);
  }

  bool search(String chinese) {
    TrieNode? node = root;

    var words = chinese.characters;
    for (var letter in words) {
      if (!node!.children.containsKey(letter)) {
        return false;
      }
      node = node.children[letter]!;
    }
    return node?.isWord ?? false;
  }

  void remove(String chinese) {
    TrieNode? node = root;
    final words = chinese.characters;
    for (final letter in words) {
      if (!node!.children.containsKey(letter)) {
        return;
      }
      node = node.children[letter]!;
    }
    node?.isWord = false;
  }

  void removePrefixWith(String chinese) {
    TrieNode? node = root;
    final words = chinese.characters;
    for (final letter in words) {
      if (!node!.children.containsKey(letter)) {
        return;
      }
      node = node.children[letter];
    }

    node?.children.clear();
    node?.shareCodeList.clear();
    node?.isWord = false;
  }

  List<String> listPrefixWith(String chinese) {
    final List<String> result = [];
    TrieNode node = root;
    for (var letter in chinese.characters) {
      if (!node.children.containsKey(letter)) {
        return result;
      }
      node = node.children[letter]!;
    }

    _insertWord(node, chinese, result);
    return result.toSet().toList(); // 去重
  }

  Map<String, List<String>> list() {
    final Map<String, List<String>> result = {};
    _insertWordToMap(root, "", result);
    return result;
  }

  int maxDepth() {
    int max = _calculateMaxDepth(root, 0);
    return max;
  }

  int wordCount() {
    int count = _calculateWordCount(root, 0);
    return count;
  }

  // 辅助方法
  void _insertWord(TrieNode node, String word, List<String> list) {
    if (node.isWord) {
      list.addAll(node.shareCodeList);
    }
    for (final entry in node.children.entries) {
      _insertWord(entry.value, word + entry.key, list);
    }
  }

  void _insertWordToMap(TrieNode node, String word, Map<String, List<String>> map) {
    if (node.isWord) {
      for (final shareCode in node.shareCodeList) {
        map.putIfAbsent(shareCode, () => []).add(word);
      }
    }
    for (final entry in node.children.entries) {
      _insertWordToMap(entry.value, word + entry.key, map);
    }
  }

  int _calculateMaxDepth(TrieNode node, int max) {
    int depth = max;
    if (node.isWord && node.depth > max) {
      depth = node.depth;
    }
    for (final child in node.children.values) {
      depth = _calculateMaxDepth(child, depth);
    }
    return depth;
  }

  int _calculateWordCount(TrieNode node, int count) {
    int wordCount = count;
    if (node.isWord) {
      count += 1;
    }
    for (final child in node.children.values) {
      wordCount = _calculateWordCount(child, wordCount);
    }
    return wordCount;
  }
}
