class FunctionTrieNode {
  Map<String, FunctionTrieNode> children = {};
  bool isFunction = false;
  String? functionName;
}

class FunctionTrie {
  final FunctionTrieNode root = FunctionTrieNode();

  // 添加内置函数到 Trie 树
  void add(String functionName) {
    FunctionTrieNode current = root;
    for (int i = 0; i < functionName.length; i++) {
      String char = functionName[i];
      current.children.putIfAbsent(char, () => FunctionTrieNode());
      current = current.children[char]!;
    }
    current.isFunction = true;
    current.functionName = functionName;
  }

  // 从输入流中匹配最长函数名
  String? matchLongestFunction(String input, int startIndex) {
    FunctionTrieNode? current = root;
    String? longestMatch;
    int matchLength = 0;

    for (int i = startIndex; i < input.length; i++) {
      String char = input[i];
      if (!current!.children.containsKey(char)) {
        break;
      }
      current = current.children[char]!;
      if (current.isFunction) {
        longestMatch = current.functionName;
        matchLength = i - startIndex + 1;
      }
    }

    return longestMatch;
  }
}
