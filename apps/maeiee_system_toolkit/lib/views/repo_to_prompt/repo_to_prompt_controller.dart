import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:maeiee_system_toolkit/views/repo_to_prompt/file_node.dart';
import 'package:path/path.dart' as path_utils;

class RepoToPromptController extends GetxController {
  final selectedPath = ''.obs;
  final generatedContent = ''.obs;
  final isLoading = false.obs;
  final statusMessage = ''.obs;

  // 拖拽悬停状态，用于 UI 反馈
  final isDraggingHover = false.obs;

  // 新增：Token 估算值
  final estimatedTokens = 0.obs;

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
    generatedContent.value = ''; // 清空旧内容

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

      // 默认生成一次
      await generatePromptFromTree();

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

    // 过滤规则
    if (_shouldIgnore(name)) return null;

    final type = await FileSystemEntity.type(path);
    final isDirectory = type == FileSystemEntityType.directory;

    if (!isDirectory) {
      // 检查扩展名
      if (_shouldIgnoreExtension(path)) return null;
      return FileNode(path: path, name: name, isDirectory: false);
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
      // 目录内文件排序
      children.sort((a, b) {
        // 文件夹排前面
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.compareTo(b.name);
      });
    } catch (e) {
      print('Access denied or error: $path');
    }

    // 如果目录是空的（或者子文件都被过滤了），是否还需要显示？
    // 为了方便，这里我们保留它，但通常也可以返回 null 隐藏空文件夹
    if (children.isEmpty) return null;

    return FileNode(
      path: path,
      name: name,
      isDirectory: true,
      children: children,
    );
  }

  // 4. 根据树的状态生成 Prompt
  Future<void> generatePromptFromTree() async {
    if (fileTreeRoots.isEmpty) return;

    // isLoading.value = true; // 体验优化：生成过程如果不卡顿，可以不转圈，或者用局部 loading
    // statusMessage.value = '正在生成 Prompt...';

    StringBuffer buffer = StringBuffer();
    int count = 0;

    for (var node in fileTreeRoots) {
      // 计算相对路径的起点：如果是单个根目录，根就是起点
      // 这里简单处理：保留原始文件名作为根开始
      count += await _recursiveReadContent(
        node,
        buffer,
        path_utils.dirname(node.path),
      );
    }

    final content = buffer.toString();
    generatedContent.value = content;
    estimatedTokens.value = _estimateTokens(content);
    // isLoading.value = false;
  }

  Future<int> _recursiveReadContent(
    FileNode node,
    StringBuffer buffer,
    String rootBase,
  ) async {
    if (!node.isSelected.value) return 0; // 如果未被勾选，直接跳过

    int count = 0;

    if (!node.isDirectory) {
      try {
        final file = File(node.path);
        final content = await file.readAsString();
        // 相对路径显示
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
        // 读取失败忽略
      }
    } else {
      for (var child in node.children) {
        count += await _recursiveReadContent(child, buffer, rootBase);
      }
    }
    return count;
  }

  // 级联切换勾选状态
  void toggleNode(FileNode node, bool? value) {
    if (value == null) return;
    node.isSelected.value = value;

    // 如果是目录，递归设置所有子节点
    if (node.isDirectory) {
      _setAllChildren(node, value);
    }

    // 触发重新生成 (可以使用防抖优化，但 K.I.S.S 这里直接调用)
    generatePromptFromTree();
  }

  void _setAllChildren(FileNode node, bool value) {
    for (var child in node.children) {
      child.isSelected.value = value;
      if (child.isDirectory) {
        _setAllChildren(child, value);
      }
    }
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

  int _estimateTokens(String text) {
    if (text.isEmpty) return 0;
    final cjkRegex = RegExp(r'[\u4E00-\u9FFF]');
    int cjkCount = cjkRegex.allMatches(text).length;
    int otherCount = text.length - cjkCount;
    double tokens = (cjkCount * 1.5) + (otherCount / 4.0);
    return tokens.ceil();
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
