import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:maeiee_system_toolkit/views/repo_to_prompt/file_node.dart';
import 'package:maeiee_system_toolkit/views/repo_to_prompt/repo_to_prompt_result_view.dart';
import 'package:path/path.dart' as path_utils;

class RepoToPromptController extends GetxController {
  final selectedPath = ''.obs;
  final generatedContent = ''.obs;
  final isLoading = false.obs;
  final statusMessage = ''.obs;

  // 拖拽悬停状态，用于 UI 反馈
  final isDraggingHover = false.obs;

  // 两个 Token 计数状态
  final estimatedTokens = 0.obs; // 首页：基于文件大小粗略估算
  final accurateTokens = 0.obs; // 结果页：基于正则精确计算

  // 新增：文件树根节点列表
  final fileTreeRoots = <FileNode>[].obs;

  // 忽略的文件或目录前缀
  final _ignorePrefixes = [
    '.',
    'build',
    'ios',
    'android',
    'web',
    'macos',
    'linux',
    'windows',
    'node_modules',
  ];
  // 忽略的文件后缀
  final _ignoreExtensions = [
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'ico',
    'svg',
    'ttf',
    'otf',
    'woff',
    'pdf',
    'lock',
  ];

  // 1. 通过文件选择器选择目录
  Future<void> pickDirectory() async {
    String? result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      selectedPath.value = result;
      await _scanAndBuildTree([result]);
    }
  }

  // 2. 处理拖拽进来的文件/目录列表
  Future<void> handleDropFiles(List<String> paths) async {
    if (paths.isEmpty) return;
    if (paths.length == 1) {
      selectedPath.value = paths.first;
    } else {
      selectedPath.value = '已导入 ${paths.length} 个项目';
    }
    await _scanAndBuildTree(paths);
  }

  // 3. 扫描并构建树结构（不读取内容，只读元数据）
  Future<void> _scanAndBuildTree(List<String> rootPaths) async {
    isLoading.value = true;
    statusMessage.value = '正在扫描目录结构...';
    fileTreeRoots.clear();
    estimatedTokens.value = 0; // 重置估算

    try {
      List<FileNode> nodes = [];
      for (var path in rootPaths) {
        final node = await _recursiveBuildNode(path);
        if (node != null) {
          nodes.add(node);
        }
      }
      // 按名称排序
      nodes.sort((a, b) => a.name.compareTo(b.name));
      fileTreeRoots.assignAll(nodes);

      // 初始计算一次大小
      _recalculateSizeEstimate();

      statusMessage.value = '结构扫描完成，请在下方剔除不需要的文件';
    } catch (e) {
      statusMessage.value = '扫描错误: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // 递归构建节点
  Future<FileNode?> _recursiveBuildNode(String path) async {
    final name = path_utils.basename(path);
    if (_shouldIgnore(name)) return null;

    final type = await FileSystemEntity.type(path);
    final isDirectory = type == FileSystemEntityType.directory;

    if (!isDirectory) {
      if (_shouldIgnoreExtension(path)) return null;
      // 获取文件大小
      int size = 0;
      try {
        size = await File(path).length();
      } catch (e) {
        // 忽略无法读取大小的文件
      }
      return FileNode(path: path, name: name, isDirectory: false, size: size);
    }

    // 处理目录
    List<FileNode> children = [];
    try {
      final directory = Directory(path);
      final entities = directory.listSync(followLinks: false);
      for (var entity in entities) {
        final childNode = await _recursiveBuildNode(entity.path);
        if (childNode != null) {
          children.add(childNode);
        }
      }
      children.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.compareTo(b.name);
      });
    } catch (e) {
      print('Access denied: $path');
    }

    if (children.isEmpty) return null;

    // 目录的大小设为 0，只统计叶子节点文件
    return FileNode(
      path: path,
      name: name,
      isDirectory: true,
      children: children,
      size: 0,
    );
  }

  // 核心改动：点击生成按钮时才执行读取
  Future<void> generateAndPreview() async {
    if (fileTreeRoots.isEmpty) return;

    // 显示全局 Loading (GetX 简单方式)
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      StringBuffer buffer = StringBuffer();
      int count = 0;

      for (var node in fileTreeRoots) {
        count += await _recursiveReadContent(
          node,
          buffer,
          path_utils.dirname(node.path),
        );
      }

      final content = buffer.toString();
      generatedContent.value = content;

      // 精确计算
      accurateTokens.value = _calculateAccurateTokens(content);

      Get.back(); // 关闭 Loading

      // 跳转到结果页
      Get.to(() => const RepoToPromptResultView());
    } catch (e) {
      Get.back();
      Get.snackbar('错误', '生成失败: $e');
    }
  }

  Future<int> _recursiveReadContent(
    FileNode node,
    StringBuffer buffer,
    String rootBase,
  ) async {
    if (!node.isSelected.value) return 0;

    int count = 0;
    if (!node.isDirectory) {
      try {
        final file = File(node.path);
        final content = await file.readAsString();
        final relativePath = node.path.replaceFirst(rootBase, '');
        final cleanPath = relativePath.startsWith(Platform.pathSeparator)
            ? relativePath.substring(1)
            : relativePath;

        buffer.writeln('## File: $cleanPath');
        buffer.writeln('```');
        buffer.writeln(content);
        buffer.writeln('```');
        buffer.writeln('');
        count++;
      } catch (e) {
        // 读取失败
      }
    } else {
      for (var child in node.children) {
        count += await _recursiveReadContent(child, buffer, rootBase);
      }
    }
    return count;
  }

  // 勾选切换
  void toggleNode(FileNode node, bool? value) {
    if (value == null) return;
    node.isSelected.value = value;
    if (node.isDirectory) {
      _setAllChildren(node, value);
    }
    // 仅重新计算估算值，不读取文件
    _recalculateSizeEstimate();
  }

  void _setAllChildren(FileNode node, bool value) {
    for (var child in node.children) {
      child.isSelected.value = value;
      if (child.isDirectory) {
        _setAllChildren(child, value);
      }
    }
  }

  // 基于文件大小的快速估算
  void _recalculateSizeEstimate() {
    int totalBytes = 0;
    for (var node in fileTreeRoots) {
      totalBytes += _recursiveCalculateSize(node);
    }
    // 经验公式：平均 1 token ≈ 4 bytes (英文) 或 3 bytes (中文 UTF8)
    // 既然主要是代码，我们按 3.5 bytes/token 估算，或者简单点按 4
    estimatedTokens.value = (totalBytes / 4).ceil();
  }

  int _recursiveCalculateSize(FileNode node) {
    if (!node.isSelected.value) return 0;
    if (!node.isDirectory) return node.size;
    int sum = 0;
    for (var child in node.children) {
      sum += _recursiveCalculateSize(child);
    }
    return sum;
  }

  // 基于内容的精确计算
  int _calculateAccurateTokens(String text) {
    if (text.isEmpty) return 0;
    final cjkRegex = RegExp(r'[\u4E00-\u9FFF]');
    int cjkCount = cjkRegex.allMatches(text).length;
    int otherCount = text.length - cjkCount;
    return (cjkCount * 1.5 + otherCount / 4.0).ceil();
  }

  // 辅助过滤逻辑
  bool _shouldIgnore(String name) {
    for (var prefix in _ignorePrefixes) {
      if (name.startsWith(prefix)) return true;
    }
    return false;
  }

  bool _shouldIgnoreExtension(String path) {
    for (var ext in _ignoreExtensions) {
      if (path.toLowerCase().endsWith('.$ext')) return true;
    }
    return false;
  }

  Future<void> copyToClipboard() async {
    if (generatedContent.value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: generatedContent.value));
    Get.snackbar(
      '成功',
      '内容已复制到剪贴板',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.teal.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
    );
  }
}
