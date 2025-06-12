// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/settings/panel_layout_setting.dart
// Purpose:     panel layout setting
// Author:      songhuabiao
// Created:     2025-06-12 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

enum PanelLayoutType {
  twoRowtwoCol, // 2*2 布局
  threeRowThreeCol, // 3*3 布局
}

enum ComponentType {
  dayKline, // 日K线
  minuteKline, // 分时图
  miniKline, //  支持 日/周/月/季/年 K线切换
  marketShareList, // 市场行情列表
  bkShareList, // 板块股票列表
  conceptShareList, // 概念股票列表
  regionShareList, // 地域股票列表
  shareRelatedList, // 个股关联板块/概念/行业列表
}

// 用户版面设置
class PanelLayoutSetting {
  String name; // 版面名称
  int posIndex; // 版面所处下表序号
  PanelLayoutSetting type; // 布局类型
  List<ComponentType> components; // 布局的填充元素
  PanelLayoutSetting({
    required this.name,
    required this.posIndex,
    required this.type,
    this.components = const [],
  });
}
