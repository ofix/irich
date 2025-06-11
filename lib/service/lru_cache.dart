// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/service/lru_cache.dart
// Purpose:     high performance LRU cache for klines
// Author:      songhuabiao
// Created:     2025-06-10 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'dart:collection';

// 高性能LRU缓存
class LRUCache<K, V> {
  final int capacity;
  final _map = HashMap<K, _Node<K, V>>();
  _Node<K, V>? _head, _tail;
  int _size = 0;

  LRUCache({this.capacity = 300});

  V? get(K key) {
    final node = _map[key];
    if (node == null) return null;
    _moveToHead(node);
    return node.value;
  }

  void put(K key, V value) {
    if (_map.containsKey(key)) {
      final node = _map[key]!;
      node.value = value;
      _moveToHead(node);
      return;
    }

    final newNode = _Node(key, value);
    _map[key] = newNode;
    _addToHead(newNode);
    _size++;

    if (_size > capacity) _evict();
  }

  // 数据预加载
  Future<void> preload(List<K> keys, Future<V> Function(K) loader) async {
    await Future.wait(
      keys.map((key) async {
        if (!_map.containsKey(key)) {
          put(key, await loader(key));
        }
      }),
    );
  }

  void _moveToHead(_Node<K, V> node) {
    if (node == _head) return;

    // 1. 从原位置移除节点
    node.prev?.next = node.next;
    node.next?.prev = node.prev;

    // 2. 如果节点是尾部，更新_tail
    if (node == _tail) {
      _tail = node.prev;
    }

    // 3. 将节点插入头部
    node.prev = null;
    node.next = _head;
    _head?.prev = node;
    _head = node;

    // 4. 处理空链表情况
    _tail ??= node;
  }

  void _addToHead(_Node<K, V> node) {
    node.prev = null;
    node.next = _head;

    if (_head != null) {
      _head!.prev = node; // 只有非空链表才更新原头节点的 prev
    } else {
      _tail = node; // 首次插入时初始化 _tail
    }

    _head = node; // 更新 _head
  }

  void _evict() {
    if (_tail == null) return;

    _map.remove(_tail!.key);
    if (_tail == _head) {
      _head = _tail = null;
    } else {
      _tail = _tail!.prev;
      _tail?.next = null;
    }
    _size--;
  }
}

class _Node<K, V> {
  K key;
  V value;
  _Node<K, V>? prev, next;
  _Node(this.key, this.value);
}
