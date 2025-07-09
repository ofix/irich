// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/formula_engine/formula_parser.dart
// Purpose:     stock formula parser
// Author:      songhuabiao
// Created:     2025-06-23 20:30
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

class FormulaAnalyzer {
  final List<FormulaFunction> functions;
  final List<String> fields;

  FormulaAnalyzer({required this.functions, required this.fields});

  AnalysisResult analyze(String input) {
    final tokenizer = FormulaTokenizer(input);
    final tokens = tokenizer.tokenize();

    final parser = FormulaParser(tokens);
    final statements = parser.parseProgram();

    return AnalysisResult(tokens: tokens, statements: statements);
  }
}

const buildInFunctions = <String>["cross", "ema", 'ma', 'if', ''];

class AnalysisResult {
  final List<Token> tokens;
  final List<Statement> statements;

  AnalysisResult({required this.tokens, required this.statements});
}

extension StringExtension on String {
  bool get isLetter {
    final codeUnit = codeUnitAt(0);
    return (codeUnit >= 65 && codeUnit <= 90) || // A-Z
        (codeUnit >= 97 && codeUnit <= 122); // a-z
  }

  bool get isUppercaseLetter {
    final codeUnit = codeUnitAt(0);
    return codeUnit >= 65 && codeUnit <= 90; // A-Z
  }

  bool get isLowercaseLetter {
    final codeUnit = codeUnitAt(0);
    return codeUnit >= 97 && codeUnit <= 122; // a-z
  }

  bool get isLetterOrDigit {
    final codeUnit = codeUnitAt(0);
    return (codeUnit >= 65 && codeUnit <= 90) || // A-Z
        (codeUnit >= 97 && codeUnit <= 122 || // a-z
            (codeUnit >= 48 && codeUnit <= 57)); // 0-9
  }

  bool get isDigit {
    final codeUnit = codeUnitAt(0);
    return (codeUnit >= 48 && codeUnit <= 57); // 0-9
  }
}

class FormulaTokenizer {
  final String input;
  final FunctionTrie functionTrie = FunctionTrie();
  int position = 0;
  int row = 0;
  int col = 0;

  FormulaTokenizer(this.input) {
    for (final function in buildInFunctions) {
      functionTrie.add(function);
    }
  }
  // 跳过空白字符
  void skipWhitespace() {
    while (position < input.length && isWhitespace(input[position])) {
      if (input[position] == '\n') {
        row++;
        col = 0;
      } else {
        col++;
      }
      position++;
    }
  }

  void advance() {
    position++;
    col++;
  }

  Token scanIdentifier() {
    final start = position;
    while (position < input.length && (isAlphaDigit(input[position]))) {
      advance();
    }

    final value = input.substring(start, position);
    return Token(type: TokenType.identifier, name: value, row: row, col: col);
  }

  Token scanDigit() {
    final start = position;
    while (position < input.length && isDigit(input[position])) {
      advance();
    }

    // 处理小数部分
    if (position < input.length && input[position] == '.') {
      advance();
      while (position < input.length && isDigit(input[position])) {
        advance();
      }
    }

    final value = input.substring(start, position);
    return Token(type: TokenType.number, name: value, row: row, col: col);
  }

  bool isAlphaDigit(String char) {
    return isAlpha(char) || isDigit(char);
  }

  bool isDigit(String char) {
    return char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
  }

  bool isAlpha(String char) {
    return (char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90) ||
        (char.codeUnitAt(0) >= 97 && char.codeUnitAt(0) <= 122) ||
        (char == '_');
  }

  bool isWhitespace(String char) {
    return char == ' ' || char == '\t' || char == '\n' || char == '\r';
  }

  Token? getNextToken() {
    if (position >= input.length) {
      return null;
    }
    skipWhitespace();
    // 检查是否为内置函数
    String? functionName = functionTrie.matchLongestFunction(input, position);
    if (functionName != null) {
      Token token = Token(type: TokenType.function, name: functionName, row: row, col: col);
      position += functionName.length;
      return token;
    }

    // 处理标识符
    if (input[position].isLetter || input[position] == '_') {
      int start = position;
      position++;
      col++;
      while (position < input.length &&
          (input[position].isLetterOrDigit || input[position] == '_')) {
        position++;
        col++;
      }
      return Token(
        type: TokenType.identifier,
        name: input.substring(start, position),
        row: row,
        col: col,
      );
    }

    // 处理数字
    if (input[position].isDigit) {
      int start = position;
      position++;
      bool hasDecimal = false;

      while (position < input.length) {
        if (input[position].isDigit) {
          position++;
        } else if (input[position] == '.' && !hasDecimal) {
          hasDecimal = true;
          position++;
        } else {
          break;
        }
      }

      return Token(
        type: TokenType.number,
        name: input.substring(start, position),
        row: row,
        col: col,
      );
    }

    // 处理单字符 Token
    switch (input[position]) {
      case '+':
        {
          return Token(type: TokenType.add, name: '+', row: row, col: col);
        }
      case '-':
        {
          return Token(type: TokenType.plus, name: '-', row: row, col: col);
        }
      case '*':
        {
          return Token(type: TokenType.multi, name: '*', row: row, col: col);
        }
      case '/':
        {
          return Token(type: TokenType.div, name: '/', row: row, col: col);
        }
      case '>':
        {
          return Token(type: TokenType.greater, name: '>', row: row, col: col);
        }
      case '>=':
        {
          return Token(type: TokenType.greaterEqual, name: '>=', row: row, col: col);
        }
      case '<':
        {
          return Token(type: TokenType.less, name: '<', row: row, col: col);
        }
      case '=':
        {
          return Token(type: TokenType.assign, name: '+', row: row, col: col);
        }
      case '!':
        {
          return Token(type: TokenType.not, name: '!', row: row, col: col);
        }
      case '(':
        {
          return Token(type: TokenType.parenLeft, name: '(', row: row, col: col);
        }
      case ')':
        {
          return Token(type: TokenType.parenRight, name: ')', row: row, col: col);
        }
      case ',':
        {
          return Token(type: TokenType.comma, name: ',', row: row, col: col);
        }
    }
    return null;
  }

  List<Token> tokenize() {
    final tokens = <Token>[];
    final buffer = StringBuffer();
    int i = 0;

    while (i < input.length) {
      final char = input[i];

      // 处理注释
      if (char == '/' && i + 1 < input.length && input[i + 1] == '/') {
        final commentStart = i;
        while (i < input.length && input[i] != '\n') {
          i++;
        }
        tokens.add(
          Token(
            type: TokenType.comment,
            name: input.substring(commentStart, i),
            row: row,
            col: col,
          ),
        );
        continue;
      }
    }
    return tokens;
  }
}

class SymbolTable {
  final Map<String, Token> variables = {};
  final Map<String, Function> functions = {};

  void addVariable(String name, Type type, [dynamic initialValue]) {
    // variables[name] = Token(value:name, type:type, offset:initialValue);
  }

  Token? lookupVariable(String name) => variables[name];
}

class FormulaParser {
  final List<Token> tokens;
  int _current = 0;

  FormulaParser(this.tokens);

  List<Statement> parseProgram() {
    final statements = <Statement>[];
    while (!_isAtEnd()) {
      statements.add(_parseStatement());
    }
    return statements;
  }

  Statement _parseStatement() {
    if (_match(TokenType.identifier) && _check(TokenType.assign)) {
      final variable = _previous().name;
      _advance(); // 消费=
      final expr = _parseExpression();
      _consume(TokenType.semicolon, '期望分号');
      return AssignmentStatement(variable, expr);
    }
    final expr = _parseExpression();
    if (!_isAtEnd()) _consume(TokenType.semicolon, '期望分号');
    return ExpressionStatement(expr);
  }

  Expression _parseExpression() => _parseLogicalOr();

  Expression _parseLogicalOr() {
    var expr = _parseLogicalAnd();
    while (_match(TokenType.or)) {
      final operator = _previous().name;
      final right = _parseLogicalAnd();
      expr = BinaryExpression(expr, operator, right);
    }
    return expr;
  }

  Expression _parseLogicalAnd() {
    // 首先解析比较表达式
    var expr = _parseComparison();

    // 循环处理连续的AND运算符
    while (_match(TokenType.and)) {
      final operator = _previous().name; // 获取AND运算符
      final right = _parseComparison(); // 解析右侧比较表达式
      expr = BinaryExpression(expr, operator, right); // 构建AST节点
    }

    return expr;
  }

  // 解析比较表达式
  Expression _parseComparison() {
    var expr = _parseAdditive();

    while (_matchAddOperator(['>', '<', '>=', '<=', '==', '!='])) {
      final operator = _previous().name;
      final right = _parseAdditive();
      expr = BinaryExpression(expr, operator, right);
    }

    return expr;
  }

  // 解析加减法
  Expression _parseAdditive() {
    var expr = _parseMultiplicative();

    while (_matchAddOperator(['+', '-'])) {
      final operator = _previous().name;
      final right = _parseMultiplicative();
      expr = BinaryExpression(expr, operator, right);
    }

    return expr;
  }

  // 解析乘除法
  Expression _parseMultiplicative() {
    var expr = _parsePrimary();

    while (_matchAddOperator(['*', '/', '%'])) {
      final operator = _previous().name;
      final right = _parsePrimary();
      expr = BinaryExpression(expr, operator, right);
    }

    return expr;
  }

  // ...其他解析方法保持不变...

  Expression _parsePrimary() {
    if (_match(TokenType.number)) {
      return Literal(double.parse(_previous().name));
    }

    if (_match(TokenType.identifier)) {
      // 可能是变量引用或函数调用
      if (_check(TokenType.parenLeft)) {
        return _parseFunctionCall();
      }
      return VariableReference(_previous().name);
    }

    if (_match(TokenType.function)) {
      return _parseFunctionCall();
    }

    if (_match(TokenType.parenLeft)) {
      final expr = _parseExpression();
      _consume(TokenType.parenRight, '期望右括号');
      return expr;
    }

    throw FormatException('期望表达式');
  }

  FunctionCall _parseFunctionCall() {
    final functionName = _previous().name;
    _consume(TokenType.parenLeft, '期望左括号');
    final arguments = <Expression>[];

    if (!_check(TokenType.parenRight)) {
      do {
        arguments.add(_parseExpression());
      } while (_match(TokenType.comma));
    }

    _consume(TokenType.parenRight, '期望右括号');
    return FunctionCall(functionName, arguments);
  }

  bool _match(TokenType type, [String? value]) {
    if (_isAtEnd()) return false;
    if (tokens[_current].type == type && (value == null || tokens[_current].name == value)) {
      _advance();
      return true;
    }
    return false;
  }

  bool _matchAddOperator(List<String> operators) {
    if (!_check(TokenType.add)) return false;
    if (!operators.contains(_peek().name)) return false;
    _advance();
    return true;
  }

  bool _check(TokenType type) {
    if (_isAtEnd()) return false;
    return _peek().type == type;
  }

  Token _advance() {
    if (!_isAtEnd()) _current++;
    return _previous();
  }

  Token _peek() => tokens[_current];

  Token _previous() => tokens[_current - 1];

  bool _isAtEnd() => _current >= tokens.length;

  void _consume(TokenType type, String message) {
    if (_check(type)) {
      _advance();
      return;
    }
    throw FormatException(message);
  }
}
