import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:irich/service/tasks/task.dart';

void testSomething() {
  Map<String, dynamic> taskJson = {
    "Type": TaskType.syncShareRegion.val,
    "Priority": TaskPriority.high.val,
    "TaskId": "x234234234sdfr34234234",
    "Status": TaskStatus.paused.val,
    "Params": jsonEncode({"code": "000001", "name": "平安银行", "pinyin": "pinganyinhang"}),
    "Progress": 0.65,
    "SubmitTime": (DateTime.now()).toIso8601String(),
    "StartTime": (DateTime.now()).toIso8601String(),
    "DoneRequests": 10,
    "OriginTotalRequests": 90,
    "TotalRequests": 90,
  };
  final task = Task.deserialize(taskJson);
  debugPrint("Task ID: ${task.taskId}");
}
