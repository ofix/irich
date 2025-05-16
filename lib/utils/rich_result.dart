// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/utils/rich_result.dart
// Purpose:     rich result for api request
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

// ignore_for_file: constant_identifier_names

enum RichStatus {
  ok,
  dataNotFound, // 数据不存在
  repeatInit, // 重复初始化
  parameterError, // 参数错误
  networkError, // 网络错误
  parseError, // 数据解析错误
  memoryAllocFailed, // 内存分配失败
  shareNotExist, // 股票不存在
  fileNotFound, // 文件不存在
  fileReadFailed, // 文件读取失败
  fileExpired, // 文件数据过期
  fileDirty, // 文件内容被污染了
  fileWriteDeny, // 文件拒绝写入
  fileWriteFailed, // 文件写入失败
  innerError, // 内部错误
  taskCancelled, // 任务被用户取消
  taskPaused, // 任务被用户暂停
}

class RichResult {
  final RichStatus status;
  final String desc;

  RichResult({this.status = RichStatus.ok, this.desc = ""});

  String what() {
    if (desc != "") {
      return desc;
    }
    switch (status) {
      case RichStatus.fileWriteFailed:
        return "文件写入失败";
      case RichStatus.fileExpired:
        return "本地数据已过期";
      case RichStatus.fileDirty:
        return "数据文件已损坏";
      case RichStatus.fileReadFailed:
        return "文件读取失败";
      case RichStatus.fileNotFound:
        return "文件不存在";
      case RichStatus.fileWriteDeny:
        return "获取文件写入权限失败";
      case RichStatus.innerError:
        return "系统内部错误";
      case RichStatus.memoryAllocFailed:
        return "内存空间不足";
      case RichStatus.networkError:
        return "网络连接失败";
      case RichStatus.parameterError:
        return "参数传入错误";
      case RichStatus.parseError:
        return "文件解析错误";
      case RichStatus.shareNotExist:
        return "股票不存在";
      case RichStatus.repeatInit:
        return "重复初始化";
      case RichStatus.taskCancelled:
        return "任务被用户取消";
      case RichStatus.taskPaused:
        return "任务被用户暂停";
      default:
        return "";
    }
  }

  bool ok() {
    return status == RichStatus.ok;
  }
}

RichResult error(RichStatus status, {String desc = ""}) {
  return RichResult(status: status, desc: desc);
}

RichResult success() {
  return RichResult(status: RichStatus.ok, desc: "");
}
