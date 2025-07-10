// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/formula_engine/formula_parser.dart
// Purpose:     stock formula parser
// Author:      songhuabiao
// Created:     2025-06-23 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:irich/service/formula_engine/formula_defines.dart';

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

class SymbolTable {
  final Map<String, Token> variables = {};
  final Map<String, Function> functions = {};

  void addVariable(String name, Type type, [dynamic initialValue]) {
    // variables[name] = Token(value:name, type:type, offset:initialValue);
  }

  Token? lookupVariable(String name) => variables[name];
}

// 选股公式语法分析器
class FormulaLexer {
  final List<Token> tokens; // 所有的token
  int pos = 0; // 当前分析的token

  FormulaLexer(this.tokens);

  List<Statement> parse() {
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
    if (tokens[pos].type == type && (value == null || tokens[pos].name == value)) {
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
    if (!_isAtEnd()) pos++;
    return _previous();
  }

  Token _peek() => tokens[pos];

  Token _previous() => tokens[pos - 1];

  bool _isAtEnd() => pos >= tokens.length;

  void _consume(TokenType type, String message) {
    if (_check(type)) {
      _advance();
      return;
    }
    throw FormatException(message);
  }
}
