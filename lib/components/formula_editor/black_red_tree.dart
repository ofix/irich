// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/formula_engine/black_red_tree.dart
// Purpose:     black red tree implementation
// Author:      songhuabiao
// Created:     2025-06-25 20:30
// Copyright:   (C) Copyright 2025, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

// 定义红黑树节点颜色
import 'package:flutter/material.dart';

enum NodeColor { red, black }

// 红黑树节点类
class RBNode<T extends Comparable> {
  T value;
  NodeColor color;
  RBNode<T>? left;
  RBNode<T>? right;
  RBNode<T>? parent;

  RBNode(this.value, {this.color = NodeColor.red}) {
    left = null;
    right = null;
    parent = null;
  }

  // 判断是否为左子节点
  bool isLeftChild() => this == parent?.left;

  // 获取叔节点
  RBNode<T>? get uncle {
    if (parent == null || parent!.parent == null) return null;
    return parent!.isLeftChild() ? parent!.parent!.right : parent!.parent!.left;
  }

  // 获取兄弟节点
  RBNode<T>? get sibling {
    if (parent == null) return null;
    return isLeftChild() ? parent!.right : parent!.left;
  }

  // 是否有红色子节点（用于删除操作）
  bool hasRedChild() =>
      (left != null && left!.color == NodeColor.red) ||
      (right != null && right!.color == NodeColor.red);
}

// 红黑树类
class RedBlackTree<T extends Comparable> {
  RBNode<T>? root;

  // 插入值
  void insert(T value) {
    var newNode = RBNode<T>(value);
    if (root == null) {
      root = newNode;
      _fixInsert(newNode);
      return;
    }

    var current = root;
    RBNode<T>? parent;

    // 查找插入位置
    while (current != null) {
      parent = current;
      if (value.compareTo(current.value) < 0) {
        current = current.left;
      } else {
        current = current.right;
      }
    }

    // 设置新节点的父节点
    newNode.parent = parent;
    if (value.compareTo(parent!.value) < 0) {
      parent.left = newNode;
    } else {
      parent.right = newNode;
    }

    _fixInsert(newNode);
  }

  // 插入后修复红黑树性质
  void _fixInsert(RBNode<T> node) {
    var parent = node.parent;

    // 情况1：新节点是根节点
    if (parent == null) {
      node.color = NodeColor.black;
      root = node;
      return;
    }

    // 情况2：父节点是黑色，无需处理
    if (parent.color == NodeColor.black) return;

    var uncle = node.uncle;
    var grandparent = parent.parent!;

    // 情况3：叔节点是红色
    if (uncle != null && uncle.color == NodeColor.red) {
      parent.color = NodeColor.black;
      uncle.color = NodeColor.black;
      grandparent.color = NodeColor.red;
      _fixInsert(grandparent); // 递归处理祖父节点
      return;
    }

    // 情况4/5：叔节点是黑色或不存在
    if (parent.isLeftChild()) {
      if (!node.isLeftChild()) {
        // 情况4：LR型
        _leftRotate(parent);
        _fixInsert(parent); // 原父节点变为子节点
      } else {
        // 情况5：LL型
        _rightRotate(grandparent);
        parent.color = NodeColor.black;
        grandparent.color = NodeColor.red;
      }
    } else {
      if (node.isLeftChild()) {
        // 情况4：RL型
        _rightRotate(parent);
        _fixInsert(parent);
      } else {
        // 情况5：RR型
        _leftRotate(grandparent);
        parent.color = NodeColor.black;
        grandparent.color = NodeColor.red;
      }
    }
  }

  // 左旋
  void _leftRotate(RBNode<T> node) {
    var rightChild = node.right!;
    node.right = rightChild.left;

    if (rightChild.left != null) {
      rightChild.left!.parent = node;
    }

    rightChild.parent = node.parent;

    if (node.parent == null) {
      root = rightChild;
    } else if (node.isLeftChild()) {
      node.parent!.left = rightChild;
    } else {
      node.parent!.right = rightChild;
    }

    rightChild.left = node;
    node.parent = rightChild;
  }

  // 右旋
  void _rightRotate(RBNode<T> node) {
    var leftChild = node.left!;
    node.left = leftChild.right;

    if (leftChild.right != null) {
      leftChild.right!.parent = node;
    }

    leftChild.parent = node.parent;

    if (node.parent == null) {
      root = leftChild;
    } else if (node.isLeftChild()) {
      node.parent!.left = leftChild;
    } else {
      node.parent!.right = leftChild;
    }

    leftChild.right = node;
    node.parent = leftChild;
  }

  // 中序遍历（验证排序性质）
  void inOrder(RBNode<T>? node, Function(T) visit) {
    if (node == null) return;
    inOrder(node.left, visit);
    visit(node.value);
    inOrder(node.right, visit);
  }

  // 打印树结构（辅助调试）
  void printTree([RBNode<T>? node, int indent = 0]) {
    node ??= root;
    if (node == null) return;

    if (node.right != null) printTree(node.right, indent + 4);

    debugPrint(' ' * indent + '${node.value}(${node.color == NodeColor.red ? "R" : "B"})');

    if (node.left != null) printTree(node.left, indent + 4);
  }
}
