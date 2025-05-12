// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/task_scheduler/isolate_worker.dart
// Purpose:     isolate worker
// Author:      songhuabiao
// Created:     2025-05-12 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:isolate';

import 'package:irich/service/task_scheduler/task.dart';
import 'package:irich/service/task_scheduler/task_events.dart';

class IsolateWorker {
  final void Function(IsolateWorker) _onIdle;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  Isolate? _isolate;

  IsolateWorker(this._onIdle);

  static Future<IsolateWorker> create(void Function(IsolateWorker) onIdle) async {
    final worker = IsolateWorker(onIdle);
    await worker._initialize();
    return worker;
  }

  Future<void> _initialize() async {
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, _receivePort!.sendPort);
    _sendPort = await _receivePort!.first as SendPort;
  }

  void execute<R>(Task<R> task) {
    _sendPort?.send(task);
  }

  Future<void> dispose() async {
    _receivePort?.close();
    _isolate?.kill();
    _isolate = null;
    _sendPort = null;
    _receivePort = null;
  }

  static void _isolateEntry(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    receivePort.listen((dynamic event) {
      if (event is NewTaskUiEvent) {
        event.task.run();
      }
    });
  }
}
