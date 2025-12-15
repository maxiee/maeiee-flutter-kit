import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class RepoToPromptController extends GetxController {
  final selectedPath = ''.obs;
  final generatedContent = ''.obs;
  final isLoading = false.obs;
  final statusMessage = ''.obs;

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

  Future<void> pickDirectory() async {
    String? result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      selectedPath.value = result;
      await _generatePrompt(Directory(result));
    }
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

  bool _shouldProcessFile(String path) {
    // 检查路径中的每一个部分是否包含忽略的前缀
    final parts = path.split(Platform.pathSeparator);
    for (var part in parts) {
      for (var prefix in _ignorePrefixes) {
        if (part.startsWith(prefix)) return false;
      }
    }

    // 检查后缀
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
      duration: const Duration(seconds: 2),
    );
  }
}
