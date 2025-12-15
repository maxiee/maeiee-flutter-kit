import 'package:get/get.dart';

class FileNode {
  final String path;
  final String name;
  final bool isDirectory;
  final List<FileNode> children;

  // 使用 RxBool 实现响应式勾选
  final RxBool isSelected = true.obs;
  // 是否展开（仅目录有效）
  final RxBool isExpanded = false.obs;

  FileNode({
    required this.path,
    required this.name,
    required this.isDirectory,
    this.children = const [],
    bool initialCheck = true,
  }) {
    isSelected.value = initialCheck;
  }
}
