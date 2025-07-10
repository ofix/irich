// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/formula_engine/formula_tokenizer.dart
// Purpose:     stock formula tokenizer
// Author:      songhuabiao
// Created:     2025-07-10 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/service/formula_engine/formula_defines.dart';
import 'package:irich/service/formula_engine/function_trie.dart';

// 语法规则定义
// program       : statement+
// statement     : assignment | expression | stragedy
// assignment    : identifier '=' expression ';'
// expression    : logicalOr
// logicalOr     : logicalAnd ('OR' logicalAnd)*
// logicalAnd    : comparison ('AND' comparison)*
// comparison    : additive (('>'|'<'|'>='|'<='|'=='|'!=') additive)*
// additive      : multiplicative (('+'|'-') multiplicative)*
// multiplicative: primary (('*'|'/'|'%') primary)*
// primary       : number | identifier | function_call | '(' expression ')'

const buildInFunctions = <String>["cross", "ema", 'ma', 'if', ''];

// 选股公式词法分析器
class FormulaTokenizer {
  final FunctionTrie functionTrie = FunctionTrie();
  String src; // 输入源码字符串，最好分块处理，暂不考虑过长的源码文件
  int begin = 0; // 记录分析的起始位置
  int pos = 0; // 当前位置
  int x = 1; // 当前源码列位置
  int y = 1; // 当前源码行位置
  String? cur; // 当前字符

  FormulaTokenizer(this.src) {
    for (final function in buildInFunctions) {
      functionTrie.add(function);
    }
  }
  // 跳过空白字符
  void skipWhitespace() {
    while (pos < src.length && isWhitespace(src[pos])) {
      if (src[pos] == '\n' || src[pos] == '\r') {
        y++;
        x = 1;
      } else {
        x++;
      }
      pos++;
    }
  }

  void advance() {
    if (pos < src.length) {
      cur = src[pos];
      if (cur == '\r' || cur == '\n') {
        y++;
        x = 1;
      } else {
        x++;
      }
      pos++;
    }
  }

  Token scanIdentifier() {
    begin = pos;
    while (isAlphaDigit(cur) || cur == '_') {
      advance();
    }
    final value = src.substring(begin, pos);
    // 检查是否为内置函数
    String? functionName = functionTrie.matchLongestFunction(src, pos);
    if (functionName != null) {
      return Token(type: TokenType.function, name: functionName, y: y, x: x);
    }
    // 检查是否是关键词或者内置函数
    return Token(type: TokenType.identifier, name: value, y: y, x: x);
  }

  // 处理行内注释
  Token scanInlineComment() {
    while (cur != '\n' || cur != '\r' || cur != null) {
      advance();
    }
    return Token(type: TokenType.inlineComment, name: src.substring(begin, pos), y: y, x: x);
  }

  // 处理行内注释
  Token? scanBlockComment() {
    while (cur != '/' && cur != null) {
      advance();
    }
    if (src[pos - 1] != '*') {
      // 注释不完整
      return null;
    }
    return Token(type: TokenType.blockComment, name: src.substring(begin, pos), y: y, x: x);
  }

  Token scanDigit() {
    begin = pos;
    while (isDigit(cur)) {
      advance();
    }
    // 处理小数部分
    if (cur == '.') {
      advance();
      while (isDigit(cur)) {
        advance();
      }
    }
    final value = src.substring(begin, pos);
    return Token(type: TokenType.number, name: value, y: y, x: x);
  }

  bool isAlphaDigit(String? char) {
    return isAlpha(char) || isDigit(char);
  }

  bool isDigit(String? char) {
    if (char == null) {
      return false;
    }
    return char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
  }

  bool isAlpha(String? char) {
    if (char == null) {
      return false;
    }
    return (char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90) ||
        (char.codeUnitAt(0) >= 97 && char.codeUnitAt(0) <= 122) ||
        (char == '_');
  }

  bool isWhitespace(String char) {
    return char == ' ' || char == '\t' || char == '\n' || char == '\r';
  }

  Token? getNextToken() {
    if (pos >= src.length) {
      return null;
    }
    skipWhitespace();
    advance();
    // 处理标识符
    if (isAlpha(cur) || cur == '_') {
      while (isAlphaDigit(cur) || cur == '_') {
        advance();
      }
      return Token(type: TokenType.identifier, name: src.substring(begin, pos), y: y, x: x);
    }

    // 处理数字
    if (isDigit(cur)) {
      scanDigit();
    }

    // 处理单字符 Token
    switch (cur) {
      case '+':
        {
          return Token(type: TokenType.add, name: '+', y: y, x: x);
        }
      case '-':
        {
          return Token(type: TokenType.plus, name: '-', y: y, x: x);
        }
      case '*':
        {
          return Token(type: TokenType.multi, name: '*', y: y, x: x);
        }
      case '/':
        {
          advance();
          if (cur == '/') {
            begin = pos - 2;
            return scanInlineComment();
          } else if (cur == '*') {
            begin = pos - 2;
            return scanBlockComment();
          }
          return Token(type: TokenType.div, name: '/', y: y, x: x);
        }
      case '>':
        {
          advance();
          if (cur == '=') {
            return Token(type: TokenType.greaterEqual, name: '>=', y: y, x: x);
          }
          return Token(type: TokenType.greater, name: '>', y: y, x: x);
        }
      case '<':
        {
          advance();
          if (cur == '=') {
            return Token(type: TokenType.assign, name: '<=', y: y, x: x);
          }
          return Token(type: TokenType.less, name: '<', y: y, x: x);
        }
      case '=':
        {
          return Token(type: TokenType.assign, name: '=', y: y, x: x);
        }
      case '!':
        {
          return Token(type: TokenType.not, name: '!', y: y, x: x);
        }
      case '(':
        {
          return Token(type: TokenType.parenLeft, name: '(', y: y, x: x);
        }
      case ')':
        {
          return Token(type: TokenType.parenRight, name: ')', y: y, x: x);
        }
      case ";":
        {
          return Token(type: TokenType.semicolon, name: ";", y: y, x: x);
        }
      case ',':
        {
          return Token(type: TokenType.comma, name: ',', y: y, x: x);
        }
    }
    return null;
  }

  List<Token> tokenize() {
    final tokens = <Token>[];
    for (;;) {
      Token? token = getNextToken();
      if (token == null) {
        break;
      }
      tokens.add(token);
    }
    return tokens;
  }
}
