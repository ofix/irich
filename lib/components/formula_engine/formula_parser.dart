// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/formula_engine/formula_parser.dart
// Purpose:     stock formula parser
// Author:      songhuabiao
// Created:     2025-06-23 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/components/formula_engine/formula_defines.dart';

// 语法规则定义
// program       : statement+
// statement     : assignment | expression
// assignment    : IDENTIFIER '=' expression ';'
// expression    : logicalOr
// logicalOr     : logicalAnd ('OR' logicalAnd)*
// logicalAnd    : comparison ('AND' comparison)*
// comparison    : additive (('>'|'<'|'>='|'<='|'=='|'!=') additive)*
// additive      : multiplicative (('+'|'-') multiplicative)*
// multiplicative: primary (('*'|'/'|'%') primary)*
// primary       : NUMBER | IDENTIFIER | FUNCTION_CALL | '(' expression ')'

class FormulaAnalyzer {
  final List<FormulaFunction> functions;
  final List<String> fields;

  FormulaAnalyzer({required this.functions, required this.fields});

  AnalysisResult analyze(String input) {
    final tokenizer = FormulaTokenizer(input, functions, fields);
    final tokens = tokenizer.tokenize();

    final parser = FormulaParser(tokens);
    final statements = parser.parseProgram();

    return AnalysisResult(tokens: tokens, statements: statements);
  }
}

class AnalysisResult {
  final List<SyntaxToken> tokens;
  final List<Statement> statements;

  AnalysisResult({required this.tokens, required this.statements});
}

class FormulaTokenizer {
  final String input;
  final List<FormulaFunction> functions;
  final List<String> fields;

  FormulaTokenizer(this.input, this.functions, this.fields);

  List<SyntaxToken> tokenize() {
    final tokens = <SyntaxToken>[];
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
          SyntaxToken(
            value: input.substring(commentStart, i),
            type: TokenType.comment,
            offset: commentStart,
          ),
        );
        continue;
      }

      // 处理函数和字段
      if (_isIdentifierStart(char)) {
        final start = i;
        while (i < input.length && _isIdentifierPart(input[i])) {
          i++;
        }
        final identifier = input.substring(start, i);

        if (functions.any((f) => f.name == identifier)) {
          tokens.add(SyntaxToken(value: identifier, type: TokenType.function, offset: start));
        } else if (fields.contains(identifier)) {
          tokens.add(SyntaxToken(value: identifier, type: TokenType.field, offset: start));
        } else {
          tokens.add(
            SyntaxToken(
              value: identifier,
              type: TokenType.field, // 假设未知标识符为字段
              offset: start,
            ),
          );
        }
        continue;
      }

      // 处理数字
      if (_isDigit(char)) {
        final start = i;
        while (i < input.length && _isDigit(input[i])) {
          i++;
        }
        if (i < input.length && input[i] == '.') {
          i++;
          while (i < input.length && _isDigit(input[i])) {
            i++;
          }
        }
        tokens.add(
          SyntaxToken(value: input.substring(start, i), type: TokenType.number, offset: start),
        );
        continue;
      }

      // 处理运算符
      if (_isOperator(char)) {
        tokens.add(SyntaxToken(value: char, type: TokenType.operator, offset: i));
        i++;
        continue;
      }

      // 新增赋值运算符识别
      if (char == '=' && i + 1 < input.length && input[i + 1] != '=') {
        tokens.add(SyntaxToken(value: char, type: TokenType.assign, offset: i));
        i++;
        continue;
      }

      // 新增分号识别
      if (char == ';') {
        tokens.add(SyntaxToken(value: char, type: TokenType.semicolon, offset: i));
        i++;
        continue;
      }

      // 处理括号和逗号
      switch (char) {
        case '(':
          tokens.add(SyntaxToken(value: char, type: TokenType.parenLeft, offset: i));
          break;
        case ')':
          tokens.add(SyntaxToken(value: char, type: TokenType.parenRight, offset: i));
          break;
        case ',':
          tokens.add(SyntaxToken(value: char, type: TokenType.comma, offset: i));
          break;
      }

      i++;
    }

    return tokens;
  }

  bool _isIdentifierStart(String char) {
    return RegExp(r'[a-zA-Z_]').hasMatch(char);
  }

  bool _isIdentifierPart(String char) {
    return RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
  }

  bool _isDigit(String char) {
    return RegExp(r'[0-9]').hasMatch(char);
  }

  bool _isOperator(String char) {
    return RegExp(r'[+\-*/%^<>=!&|]').hasMatch(char);
  }
}

class SymbolTable {
  final Map<String, SyntaxToken> variables = {};
  final Map<String, Function> functions = {};

  void addVariable(String name, Type type, [dynamic initialValue]) {
    // variables[name] = SyntaxToken(value:name, type:type, offset:initialValue);
  }

  SyntaxToken? lookupVariable(String name) => variables[name];
}

class FormulaParser {
  final List<SyntaxToken> tokens;
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
      final variable = _previous().value;
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
    while (_match(TokenType.logic, 'OR')) {
      final operator = _previous().value;
      final right = _parseLogicalAnd();
      expr = BinaryExpression(expr, operator, right);
    }
    return expr;
  }

  Expression _parseLogicalAnd() {
    // 首先解析比较表达式
    var expr = _parseComparison();

    // 循环处理连续的AND运算符
    while (_match(TokenType.logic, 'AND')) {
      final operator = _previous().value; // 获取AND运算符
      final right = _parseComparison(); // 解析右侧比较表达式
      expr = BinaryExpression(expr, operator, right); // 构建AST节点
    }

    return expr;
  }

  // 解析比较表达式
  Expression _parseComparison() {
    var expr = _parseAdditive();

    while (_matchAnyOperator(['>', '<', '>=', '<=', '==', '!='])) {
      final operator = _previous().value;
      final right = _parseAdditive();
      expr = BinaryExpression(expr, operator, right);
    }

    return expr;
  }

  // 解析加减法
  Expression _parseAdditive() {
    var expr = _parseMultiplicative();

    while (_matchAnyOperator(['+', '-'])) {
      final operator = _previous().value;
      final right = _parseMultiplicative();
      expr = BinaryExpression(expr, operator, right);
    }

    return expr;
  }

  // 解析乘除法
  Expression _parseMultiplicative() {
    var expr = _parsePrimary();

    while (_matchAnyOperator(['*', '/', '%'])) {
      final operator = _previous().value;
      final right = _parsePrimary();
      expr = BinaryExpression(expr, operator, right);
    }

    return expr;
  }

  // ...其他解析方法保持不变...

  Expression _parsePrimary() {
    if (_match(TokenType.number)) {
      return Literal(double.parse(_previous().value));
    }

    if (_match(TokenType.field)) {
      return FieldReference(_previous().value);
    }

    if (_match(TokenType.identifier)) {
      // 可能是变量引用或函数调用
      if (_check(TokenType.parenLeft)) {
        return _parseFunctionCall();
      }
      return VariableReference(_previous().value);
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
    final functionName = _previous().value;
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
    if (tokens[_current].type == type && (value == null || tokens[_current].value == value)) {
      _advance();
      return true;
    }
    return false;
  }

  bool _matchAnyOperator(List<String> operators) {
    if (!_check(TokenType.operator)) return false;
    if (!operators.contains(_peek().value)) return false;
    _advance();
    return true;
  }

  bool _check(TokenType type) {
    if (_isAtEnd()) return false;
    return _peek().type == type;
  }

  SyntaxToken _advance() {
    if (!_isAtEnd()) _current++;
    return _previous();
  }

  SyntaxToken _peek() => tokens[_current];

  SyntaxToken _previous() => tokens[_current - 1];

  bool _isAtEnd() => _current >= tokens.length;

  void _consume(TokenType type, String message) {
    if (_check(type)) {
      _advance();
      return;
    }
    throw FormatException(message);
  }
}
