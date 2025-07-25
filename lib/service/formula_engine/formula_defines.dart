// 公式模型
import 'package:flutter/material.dart';

class StockFormula {
  final String name;
  final String expression;
  final String description;
  final DateTime createdAt;

  StockFormula({
    required this.name,
    required this.expression,
    required this.description,
    required this.createdAt,
  });
}

// 语法标记类型
enum TokenType {
  strategy, // 策略
  function, // 内置函数
  identifier, // 标识符
  add, // +
  plus, // -
  multi, // *
  div, // /
  greater, // >
  greaterEqual, // >=
  less, // <
  lessEqual, // <=
  assign, // =
  number, // 0-9.0-9
  parenLeft, // (
  parenRight, // )
  comma, // ,
  comment, // //
  inlineComment, // //
  blockComment, // /* */
  semicolon, // ;
  not, // !
  or, // ||
  and, // &&
  dot, // .
  string, // string
}

/// 表示公式中的一个语法标记
class Token {
  final TokenType type; // 标记的类型
  final String name; // 标记在源代码中的原始字符串值
  final int y; // 第几行
  final int x; // 第几列

  /// 构造函数
  const Token({required this.type, required this.name, required this.y, required this.x});

  @override
  String toString() => 'Token($type, "$name")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Token &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          name == other.name &&
          y == other.y &&
          x == other.x;

  @override
  int get hashCode => type.hashCode ^ name.hashCode ^ y.hashCode ^ x.hashCode;
}

class FormulaError {
  int errorCode; // 错误码
  String zhMsg; // 中文错误描述信息
  String enMsg; // 英文错误描述信息
  FormulaError(this.errorCode, this.zhMsg, this.enMsg);
}

// 语法高亮颜色配置
const syntaxHighlighting = {
  TokenType.function: Colors.blue,
  TokenType.number: Colors.orange,
  TokenType.comment: Colors.grey,
};

// 基础 AST 节点类
abstract class AstNode {
  const AstNode();

  // 接受访问者模式
  R accept<R>(AstVisitor<R> visitor);
}

// 表达式基类
abstract class Expression extends AstNode {}

// 语句基类
abstract class Statement extends AstNode {}

// 二元表达式节点
class BinaryExpression extends Expression {
  final Expression left;
  final String operator;
  final Expression right;

  BinaryExpression(this.left, this.operator, this.right);

  @override
  R accept<R>(AstVisitor<R> visitor) => visitor.visitBinaryExpression(this);
}

// 函数调用节点
class FunctionCall extends Expression {
  final String name;
  final List<Expression> arguments;

  FunctionCall(this.name, this.arguments);

  @override
  R accept<R>(AstVisitor<R> visitor) => visitor.visitFunctionCall(this);
}

// 字段引用节点
class FieldReference extends Expression {
  final String name;

  FieldReference(this.name);

  @override
  R accept<R>(AstVisitor<R> visitor) => visitor.visitFieldReference(this);
}

// 变量引用节点
class VariableReference extends Expression {
  final String name;

  VariableReference(this.name);

  @override
  R accept<R>(AstVisitor<R> visitor) => visitor.visitVariableReference(this);
}

// 字面量节点
class Literal extends Expression {
  final dynamic value;

  Literal(this.value);

  @override
  R accept<R>(AstVisitor<R> visitor) => visitor.visitLiteral(this);
}

// 赋值语句
class AssignmentStatement extends Statement {
  final String variable;
  final Expression expression;

  AssignmentStatement(this.variable, this.expression);

  @override
  R accept<R>(AstVisitor<R> visitor) => visitor.visitAssignmentStatement(this);
}

// 表达式语句
class ExpressionStatement extends Statement {
  final Expression expression;

  ExpressionStatement(this.expression);

  @override
  R accept<R>(AstVisitor<R> visitor) => visitor.visitExpressionStatement(this);
}

// 访问者模式接口
abstract class AstVisitor<R> {
  R visitBinaryExpression(BinaryExpression node);
  R visitFunctionCall(FunctionCall node);
  R visitFieldReference(FieldReference node);
  R visitVariableReference(VariableReference node);
  R visitLiteral(Literal node);
  R visitAssignmentStatement(AssignmentStatement node);
  R visitExpressionStatement(ExpressionStatement node);
}

/// 表示公式系统中的函数定义
class FormulaFunction {
  /// 函数名称（如 MA, EMA, CROSS）
  final String name;

  /// 函数描述（用于文档和提示）
  final String description;

  /// 参数列表（包含参数名称和类型）
  final List<FunctionParameter> parameters;

  /// 返回值类型
  final FormulaType returnType;

  /// 是否可变参数函数
  final bool isVariadic;

  /// 构造函数
  const FormulaFunction({
    required this.name,
    required this.description,
    required this.parameters,
    required this.returnType,
    this.isVariadic = false,
  });

  /// 创建简单函数（固定参数数量）
  factory FormulaFunction.simple({
    required String name,
    required String description,
    required List<FormulaType> paramTypes,
    required FormulaType returnType,
  }) {
    return FormulaFunction(
      name: name,
      description: description,
      parameters:
          paramTypes
              .asMap()
              .entries
              .map((e) => FunctionParameter(name: 'param${e.key + 1}', type: e.value))
              .toList(),
      returnType: returnType,
    );
  }

  /// 获取参数数量
  int get parameterCount => parameters.length;

  /// 检查参数是否匹配
  bool matchesArguments(List<FormulaType> argumentTypes) {
    if (!isVariadic && argumentTypes.length != parameters.length) {
      return false;
    }

    for (int i = 0; i < parameters.length; i++) {
      if (i >= argumentTypes.length) break;
      if (!parameters[i].type.isAssignableFrom(argumentTypes[i])) {
        return false;
      }
    }

    return true;
  }

  @override
  String toString() {
    final params = parameters.map((p) => '${p.type} ${p.name}').join(', ');
    return '$returnType $name($params)';
  }
}

/// 函数参数定义
class FunctionParameter {
  final String name;
  final FormulaType type;

  const FunctionParameter({required this.name, required this.type});
}

/// 公式类型系统
enum FormulaType {
  number('数字'),
  series('序列'),
  boolean('布尔'),
  string('字符串'),
  any('任意类型');

  final String displayName;
  const FormulaType(this.displayName);

  /// 检查类型是否兼容
  bool isAssignableFrom(FormulaType other) {
    return this == any || other == any || this == other;
  }
}

// 语法错误信息
enum LexerError {
  missingQuote(101, '缺少双引号', 'missing double quote'),
  invalidNumber(102, '非法的数字', 'invalid floatint number');

  final int code;
  final String chinese; // 中文描述
  final String english; // 英文描述
  const LexerError(this.code, this.chinese, this.english);

  // 数字转枚举的工厂方法
  static LexerError fromVal(int value) {
    switch (value) {
      case 101:
        return LexerError.missingQuote;
      case 102:
        return LexerError.invalidNumber;
      default:
        throw ArgumentError('Invalid market code: $value');
    }
  }
}
