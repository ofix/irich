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
  void insert(String word, String shareCode) {
    TrieNode node = root;
    int i = 0;
    while (i < word.length) {
      final character = _nextUtf8Char(word, i);
      i += character.length;

      if (!node.children.containsKey(character)) {
        node.children[character] = TrieNode(node.depth + 1);
      }
      node = node.children[character]!;
    }
    node.isWord = true;
    node.shareCodeList.add(shareCode);
  }

  bool search(String word) {
    TrieNode? node = root;
    int i = 0;
    while (i < word.length) {
      final character = _nextUtf8Char(word, i);
      i += character.length;

      if (!node!.children.containsKey(character)) {
        return false;
      }
      node = node.children[character]!;
    }
    return node?.isWord ?? false;
  }

  void remove(String word) {
    TrieNode? node = root;
    int i = 0;
    while (i < word.length) {
      final character = _nextUtf8Char(word, i);
      i += character.length;

      if (!node!.children.containsKey(character)) {
        return;
      }
      node = node.children[character]!;
    }
    node?.isWord = false;
  }

  void removePrefixWith(String word) {
    TrieNode? node = root;
    int i = 0;
    while (i < word.length) {
      final character = _nextUtf8Char(word, i);
      i += character.length;

      if (!node!.children.containsKey(character)) {
        return;
      }
      node = node.children[character];
    }

    node?.children.clear();
    node?.shareCodeList.clear();
    node?.isWord = false;
  }

  List<String> listPrefixWith(String word) {
    final List<String> result = [];
    TrieNode node = root;
    int i = 0;

    while (i < word.length) {
      final character = _nextUtf8Char(word, i);
      i += character.length;

      if (!node.children.containsKey(character)) {
        return result;
      }
      node = node.children[character]!;
    }

    _insertWord(node, word, result);
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

  void _insertWordToMap(
    TrieNode node,
    String word,
    Map<String, List<String>> map,
  ) {
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

  String _nextUtf8Char(String str, int start) {
    if (start >= str.length) return '';

    final codeUnit = str.codeUnitAt(start);
    if (codeUnit < 0x80) {
      return str[start];
    } else if (codeUnit < 0xE0) {
      return str.substring(start, start + 2);
    } else if (codeUnit < 0xF0) {
      return str.substring(start, start + 3);
    } else {
      return str.substring(start, start + 4);
    }
  }
}
