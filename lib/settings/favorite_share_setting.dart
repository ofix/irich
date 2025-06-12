// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/settings/favorite_share_setting.dart
// Purpose:     favorite share setting
// Author:      songhuabiao
// Created:     2025-06-12 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:irich/global/config.dart';
import 'package:irich/global/stock.dart';
import 'package:irich/store/store_quote.dart';
import 'package:irich/utils/file_tool.dart';

class FavoriteShareSetting {
  List<Share> _favoriteShares = [];
  // 将List<Share>序列化为JSON字符串（仅保存code）

  String serialize() {
    final codes = _favoriteShares.map((share) => share.code).toList();
    return jsonEncode(codes);
  }

  // 从JSON字符串反序列化为List<String>（股票代码列表）
  List<String> deserialize(String jsonString) {
    try {
      final json = jsonDecode(jsonString);
      if (json is! List) return [];

      // 优化点1：预分配列表大小
      final result = List<String>.filled(json.length, '');

      // 优化点2：避免双重转换（dynamic→Object→String）
      for (var i = 0; i < json.length; i++) {
        result[i] = '${json[i]}'; // 快速转换为字符串
      }
      return result;
    } catch (e) {
      debugPrint('反序列化自选股列表出错: $e');
      return [];
    }
  }

  /// 添加股票到自选股
  void addFavoriteShare(String shareCode) {
    Share? share = StoreQuote.query(shareCode);
    if (share != null) {
      share.isFavorite = true;
      _favoriteShares.add(share);
      saveFavoriteShares();
    }
  }

  /// 从自选股中删除股票
  void removeFavoriteShare(String shareCode) {
    Share? share = StoreQuote.query(shareCode);
    if (share != null) {
      share.isFavorite = false;
      _favoriteShares.removeWhere((share) => share.code == shareCode);
      saveFavoriteShares();
    }
  }

  /// 从文件中加载最选股列表
  Future<bool> loadFavoriteShares() async {
    final pathFavoriteShares = await Config.pathFavoriteShares;
    if (await FileTool.isFileExist(pathFavoriteShares)) {
      try {
        _favoriteShares.clear();
        String data = await FileTool.loadFile(pathFavoriteShares);
        List<dynamic> rawList = jsonDecode(data) as List<dynamic>;
        List<String> shareCodes = rawList.cast<String>();
        for (final shareCode in shareCodes) {
          Share? share = StoreQuote.query(shareCode);
          if (share != null) {
            _favoriteShares.add(share);
          }
        }
        return true;
      } catch (e, stackTrace) {
        debugPrint("Error load favorite shares: $e");
        debugPrint(stackTrace.toString());
        return false;
      }
    }
    return true;
  }

  // 保存最选股列表
  Future<bool> saveFavoriteShares() async {
    List<String> shareCodes = [];
    for (final share in _favoriteShares) {
      shareCodes.add(share.code);
    }
    String data = jsonEncode(shareCodes);
    return FileTool.saveFile(await Config.pathFavoriteShares, data);
  }
}
