// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/settings/ema_curve_setting.dart
// Purpose:     ema curve setting
// Author:      songhuabiao
// Created:     2025-06-12 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:convert';

import 'package:flutter/material.dart';

class EmaCurveSetting {
  final int period; // 周期
  final Color color; // 颜色
  final bool visible; // 是否显示
  const EmaCurveSetting({required this.period, required this.color, this.visible = true});
  EmaCurveSetting copyWith({int? period, Color? color, bool? visible}) {
    return EmaCurveSetting(
      period: period ?? this.period,
      color: color ?? this.color,
      visible: visible ?? this.visible,
    );
  }

  // 序列化为Map
  Map<String, dynamic> serialize() {
    return {
      'Period': period,
      'Color': color.value, // 将Color转换为ARGB整数值
      'Visible': visible,
    };
  }

  // 从JSON字符串反序列化为List<EmaCurveSetting>
  List<EmaCurveSetting> deserializeList(String data) {
    try {
      // 优化点1：一次性类型转换
      final listJson = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
      // 优化点2：预分配固定大小列表
      final result = List<EmaCurveSetting>.filled(
        listJson.length,
        const EmaCurveSetting(period: 0, color: Colors.transparent),
        growable: false,
      );
      // 优化点3：避免迭代器开销的直接索引访问
      for (var i = 0; i < listJson.length; i++) {
        result[i] = EmaCurveSetting.deserialize(listJson[i]);
      }
      return result;
    } catch (e) {
      debugPrint('EmaCurveSetting列表反序列化出错: $e');
      return const []; // 返回不可变的空列表
    }
  }

  // 从Map反序列化
  factory EmaCurveSetting.deserialize(Map<String, dynamic> json) {
    return EmaCurveSetting(
      period: json['Period'] as int,
      color: Color(json['Color'] as int),
      visible: json['Visible'] as bool? ?? true, // 默认值为true
    );
  }

  // 重写==和hashCode
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmaCurveSetting &&
          runtimeType == other.runtimeType &&
          period == other.period &&
          color == other.color &&
          visible == other.visible;

  @override
  int get hashCode => period.hashCode ^ color.hashCode ^ visible.hashCode;

  @override
  String toString() {
    return 'EmaCurveSetting{period: $period, color: $color, visible: $visible}';
  }
}

const defaultEmaCurveSettings = [
  EmaCurveSetting(period: 5, color: Colors.white),
  EmaCurveSetting(period: 10, color: Color.fromARGB(255, 236, 9, 202)),
  EmaCurveSetting(period: 20, color: Color.fromARGB(255, 72, 105, 239)),
  EmaCurveSetting(period: 30, color: Color(0xFFFF9F1A)),
  EmaCurveSetting(period: 60, color: Color.fromARGB(255, 11, 180, 218)),
  EmaCurveSetting(period: 255, color: Color.fromARGB(255, 245, 16, 16)),
  EmaCurveSetting(period: 905, color: Color.fromARGB(255, 24, 245, 146)),
];
