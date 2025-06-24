// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/formula_engine/formula_editor.dart
// Purpose:     stock formula editor
// Author:      songhuabiao
// Created:     2025-06-23 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:irich/service/formula_engine/formula_completer.dart';
import 'package:irich/service/formula_engine/formula_defines.dart';
import 'package:irich/service/formula_engine/formula_engine.dart';
import 'package:irich/service/formula_engine/formula_parser.dart';

class FormulaEditorScreen extends StatefulWidget {
  final StockFormula? initialFormula = null;

  const FormulaEditorScreen({super.key});

  @override
  State<FormulaEditorScreen> createState() => _FormulaEditorScreenState();
}

class _FormulaEditorScreenState extends State<FormulaEditorScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<SyntaxToken> _tokens = [];
  List<Statement> _statements = []; // 初始值为一个空的 AST 节点
  List<CompletionItem> _completions = [];
  int _cursorPosition = 0;

  // 知识库配置
  final List<FormulaFunction> _functions = [
    FormulaFunction(
      name: 'MA',
      description: '计算移动平均',
      parameters: [
        FunctionParameter(name: 'series', type: FormulaType.number),
        FunctionParameter(name: 'period', type: FormulaType.number),
      ],
      returnType: FormulaType.number,
    ),
    FormulaFunction(
      name: 'EMA',
      description: '计算指数移动平均',
      parameters: [
        FunctionParameter(name: 'series', type: FormulaType.number),
        FunctionParameter(name: 'period', type: FormulaType.number),
      ],
      returnType: FormulaType.number,
    ),
    FormulaFunction(
      name: 'CROSS',
      description: '判断两条线是否交叉',
      parameters: [
        FunctionParameter(name: 'series1', type: FormulaType.number),
        FunctionParameter(name: 'series2', type: FormulaType.number),
      ],
      returnType: FormulaType.boolean,
    ),
  ];

  final List<String> _fields = ['OPEN', 'HIGH', 'LOW', 'CLOSE', 'VOLUME'];

  @override
  void initState() {
    super.initState();
    if (widget.initialFormula != null) {
      _controller.text = widget.initialFormula!.expression;
      _analyzeFormula();
    }

    _focusNode.addListener(_updateCursorPosition);
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    _analyzeFormula();
    _updateCompletions();
  }

  void _updateCursorPosition() {
    setState(() {
      _cursorPosition = _controller.selection.baseOffset;
    });
  }

  Future<void> _analyzeFormula() async {
    final analyzer = FormulaAnalyzer(functions: _functions, fields: _fields);

    final result = analyzer.analyze(_controller.text);

    setState(() {
      _tokens = result.tokens;
      _statements = result.statements;
    });
  }

  void _updateCompletions() {
    final completer = FormulaCompleter(
      functions: _functions,
      fields: _fields,
      text: _controller.text,
      cursorPosition: _cursorPosition,
    );

    setState(() {
      _completions = completer.getCompletions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('选股公式编辑器'),
        actions: [
          IconButton(icon: Icon(Icons.play_arrow), onPressed: _testFormula, tooltip: '测试公式'),
          IconButton(icon: Icon(Icons.save), onPressed: _saveFormula, tooltip: '保存公式'),
        ],
      ),
      body: Column(
        children: [
          // 编辑器区域
          _buildEditor(),
          // 诊断信息
          // 函数面板
          _buildFunctionPanel(),
        ],
      ),
      bottomSheet: _completions.isNotEmpty ? _buildCompletions() : null,
    );
  }

  Widget _buildEditor() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Stack(
        children: [
          // 语法高亮背景
          Text.rich(
            TextSpan(
              children:
                  _tokens
                      .map(
                        (token) => TextSpan(
                          text: token.value,
                          style: TextStyle(
                            color: syntaxHighlighting[token.type],
                            backgroundColor:
                                token.type == TokenType.comment ? Colors.grey[100] : null,
                          ),
                        ),
                      )
                      .toList(),
            ),
            style: TextStyle(fontSize: 16),
          ),
          // 可编辑文本框
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: 5,
            style: TextStyle(
              fontSize: 16,
              color: Colors.transparent, // 隐藏原始文本
              height: 1.5,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
              isDense: false,
            ),
            cursorColor: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionPanel() {
    return Container(
      padding: EdgeInsets.all(8),
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _functions.map((func) => _buildFunctionCard(func)).toList(),
      ),
    );
  }

  Widget _buildFunctionCard(FormulaFunction func) {
    return Card(
      child: InkWell(
        onTap: () => _insertFunction(func),
        child: Container(
          width: 160,
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(func.name, style: TextStyle(fontWeight: FontWeight.bold)),
              Text(func.description, style: TextStyle(fontSize: 12)),
              if (func.parameters.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  '参数: ${func.parameters.join(', ')}',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletions() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: ListView.builder(
        itemCount: _completions.length,
        itemBuilder:
            (ctx, index) => ListTile(
              title: Text(_completions[index].label),
              subtitle:
                  _completions[index].detail != null ? Text(_completions[index].detail!) : null,
              onTap: () => _applyCompletion(_completions[index]),
            ),
      ),
    );
  }

  void _insertFunction(FormulaFunction func) {
    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;

    String insertion;
    if (func.parameters.isEmpty) {
      insertion = '${func.name}()';
    } else {
      insertion = '${func.name}(${func.parameters.map((p) => '{$p}').join(', ')})';
    }

    _controller.text = text.substring(0, cursorPos) + insertion + text.substring(cursorPos);

    _controller.selection = TextSelection.collapsed(offset: cursorPos + insertion.indexOf('{') + 1);
  }

  void _applyCompletion(CompletionItem item) {
    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;

    // 获取当前单词的起始位置
    final wordStart = _findWordStart(text, cursorPos);
    final wordEnd = _findWordEnd(text, cursorPos);

    _controller.text = text.substring(0, wordStart) + item.insertText + text.substring(wordEnd);

    _controller.selection = TextSelection.collapsed(offset: wordStart + item.insertText.length);
  }

  int _findWordStart(String text, int position) {
    if (position > text.length) position = text.length;

    int start = position;
    while (start > 0 && _isWordChar(text[start - 1])) {
      start--;
    }
    return start;
  }

  int _findWordEnd(String text, int position) {
    if (position >= text.length) return text.length;

    int end = position;
    while (end < text.length && _isWordChar(text[end])) {
      end++;
    }
    return end;
  }

  bool _isWordChar(String char) {
    return char.contains(RegExp(r'[\w_]'));
  }

  Future<void> _testFormula() async {
    final engine = FormulaEngine();
    try {
      // final result = await engine.evaluate(_astNode);
      // _showResultDialog('公式测试成功', '返回结果: $result');
    } catch (e) {
      _showResultDialog('公式错误', e.toString());
    }
  }

  Future<void> _saveFormula() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('请输入公式内容')));
      return;
    }

    final formula = StockFormula(
      name: '未命名公式 ${DateTime.now().millisecondsSinceEpoch}',
      expression: _controller.text,
      description: '',
      createdAt: DateTime.now(),
    );

    // 保存到数据库
    Navigator.pop(context);
  }

  void _showResultDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('确定'))],
          ),
    );
  }
}
