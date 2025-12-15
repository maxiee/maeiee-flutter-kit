import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
      await _generatePrompt(Directory(result));
    }
  }

  // 2. 处理拖拽进来的文件/目录列表
  Future<void> handleDropFiles(List<String> paths) async {
    if (paths.isEmpty) return;

    // 更新 UI 显示，如果是多个文件，显示数量
    if (paths.length == 1) {
      selectedPath.value = paths.first;
    } else {
      selectedPath.value = '已导入 ${paths.length} 个项目';
    }

    await _processPaths(paths);
  }

  // 核心处理逻辑：支持列表
  Future<void> _processPaths(List<String> rootPaths) async {
    isLoading.value = true;
    statusMessage.value = '正在扫描...';
    generatedContent.value = '';

    StringBuffer buffer = StringBuffer();
    int count = 0;

    try {
      // 遍历所有输入的根路径（可能是文件，可能是文件夹）
      for (var rootPath in rootPaths) {
        final entity = FileSystemEntity.isDirectorySync(rootPath)
            ? Directory(rootPath)
            : File(rootPath);

        if (entity is File) {
          if (_shouldProcessFile(entity.path)) {
            await _appendFileContent(
              buffer,
              entity,
              path_utils.basename(entity.path),
            );
            count++;
          }
        } else if (entity is Directory) {
          // 递归处理目录
          final entities = entity.listSync(recursive: true, followLinks: false);
          entities.sort((a, b) => a.path.compareTo(b.path));

          for (var subEntity in entities) {
            if (subEntity is File && _shouldProcessFile(subEntity.path)) {
              // 计算相对路径：相对于当前正在处理的 rootPath
              final relativePath = subEntity.path.replaceFirst(rootPath, '');
              // 这里的 relativePath 可能会带上前导斜杠，美化一下
              final cleanPath = relativePath.startsWith(Platform.pathSeparator)
                  ? relativePath.substring(1)
                  : relativePath;

              // 最好带上根目录名，这样上下文更清晰 (例如: lib/main.dart)
              final contextPath = path_utils.join(
                path_utils.basename(rootPath),
                cleanPath,
              );

              await _appendFileContent(buffer, subEntity, contextPath);
              count++;
            }
          }
        }
      }
      final finalString = buffer.toString();
      generatedContent.value = finalString;
      estimatedTokens.value = _estimateTokens(finalString);
      statusMessage.value = '处理完成，共包含 $count 个文件';
    } catch (e) {
      statusMessage.value = '发生错误: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _appendFileContent(
    StringBuffer buffer,
    File file,
    String displayPath,
  ) async {
    try {
      final content = await file.readAsString();
      buffer.writeln('## File: $displayPath');
      buffer.writeln('```');
      buffer.writeln(content);
      buffer.writeln('```');
      buffer.writeln('');
    } catch (e) {
      print('Skipping binary or unreadable file: ${file.path}');
    }
  }

  bool _shouldProcessFile(String path) {
    final parts = path.split(Platform.pathSeparator);
    for (var part in parts) {
      for (var prefix in _ignorePrefixes) {
        if (part.startsWith(prefix)) return false;
      }
    }
    for (var ext in _ignoreExtensions) {
      if (path.toLowerCase().endsWith('.$ext')) return false;
    }
    return true;
  }

  Future<void> copyToClipboard() async {
    if (generatedContent.value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: generatedContent.value));
    Get.snackbar(
      '成功',
      '内容已复制到剪贴板',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.primaryColor.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _generatePrompt(Directory dir) async {
    isLoading.value = true;
    statusMessage.value = '正在扫描文件...';
    generatedContent.value = '';

    StringBuffer buffer = StringBuffer();

    try {
      // 递归列出所有文件
      final entities = dir.listSync(recursive: true, followLinks: false);

      // 排序，保证顺序一致性
      entities.sort((a, b) => a.path.compareTo(b.path));

      int count = 0;
      for (var entity in entities) {
        if (entity is File) {
          if (_shouldProcessFile(entity.path)) {
            final relativePath = entity.path.replaceFirst(dir.path, '');
            try {
              final content = await entity.readAsString();
              buffer.writeln('## File: $relativePath');
              buffer.writeln('```');
              buffer.writeln(content);
              buffer.writeln('```');
              buffer.writeln('');
              count++;
            } catch (e) {
              // 读取失败（可能是二进制文件），跳过
              print('Skipping binary or unreadable file: ${entity.path}');
            }
          }
        }
      }

      generatedContent.value = buffer.toString();
      statusMessage.value = '处理完成，共包含 $count 个文件';
    } catch (e) {
      statusMessage.value = '发生错误: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // 纯 Dart 的 Token 估算算法
  int _estimateTokens(String text) {
    if (text.isEmpty) return 0;

    // 使用正则匹配中文字符 (CJK Unified Ideographs 范围)
    // 这不会极其精准，但对于估算上下文窗口足够了
    final cjkRegex = RegExp(r'[\u4E00-\u9FFF]');

    // 统计中文字符数量
    int cjkCount = cjkRegex.allMatches(text).length;

    // 剩余字符视作英文/代码符号
    int otherCount = text.length - cjkCount;

    // 经验公式：
    // 中文：加权 1.5 (保守估计)
    // 英文/代码：加权 0.25 (即 1/4)
    double tokens = (cjkCount * 1.5) + (otherCount / 4.0);

    return tokens.ceil();
  }
}
