import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:maeiee_system_toolkit/views/repo_to_prompt/file_node.dart'; // 引入模型
import 'package:maeiee_system_toolkit/views/repo_to_prompt/repo_to_prompt_controller.dart';

class RepoToPromptView extends GetView<RepoToPromptController> {
  const RepoToPromptView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('源码转 Prompt')),
      body: DropTarget(
        onDragDone: (detail) {
          final paths = detail.files.map((e) => e.path).toList();
          controller.handleDropFiles(paths);
          controller.isDraggingHover.value = false;
        },
        onDragEntered: (detail) => controller.isDraggingHover.value = true,
        onDragExited: (detail) => controller.isDraggingHover.value = false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildControlPanel(),
              ),
              // 文件树现在占据主要空间
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildFileTreeArea(),
                ),
              ),
              // 底部操作栏
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileTreeArea() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(
                  Icons.account_tree_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text(
                  '文件结构筛选',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: Obx(() {
              if (controller.fileTreeRoots.isEmpty) {
                return const Center(
                  child: Text('请先导入项目', style: TextStyle(color: Colors.grey)),
                );
              }
              return ListView.builder(
                itemCount: controller.fileTreeRoots.length,
                itemBuilder: (context, index) {
                  return _buildFileNode(controller.fileTreeRoots[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // 递归构建树节点组件
  Widget _buildFileNode(FileNode node) {
    Widget leadingIcon;
    if (node.isDirectory) {
      leadingIcon = const Icon(Icons.folder, size: 16, color: Colors.amber);
    } else {
      leadingIcon = const Icon(
        Icons.insert_drive_file,
        size: 16,
        color: Colors.blueGrey,
      );
    }

    if (node.isDirectory) {
      return Obx(
        () => ExpansionTile(
          key: PageStorageKey(node.path),
          initiallyExpanded: node.isExpanded.value,
          onExpansionChanged: (val) => node.isExpanded.value = val,
          tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          visualDensity: VisualDensity.compact,
          leading: SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: node.isSelected.value,
              onChanged: (val) => controller.toggleNode(node, val),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: Colors.teal,
            ),
          ),
          title: Row(
            children: [
              leadingIcon,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.name,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.only(left: 20),
          children: node.children
              .map((child) => _buildFileNode(child))
              .toList(),
        ),
      );
    } else {
      return Obx(
        () => ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 0,
          ),
          visualDensity: VisualDensity.compact,
          leading: SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: node.isSelected.value,
              onChanged: (val) => controller.toggleNode(node, val),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: Colors.teal,
            ),
          ),
          title: Row(
            children: [
              leadingIcon,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.name,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 显示单个文件的大小
              Text(
                _formatFileSize(node.size),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          onTap: () => controller.toggleNode(node, !node.isSelected.value),
        ),
      );
    }
  }

  Widget _buildControlPanel() {
    return Obx(() {
      final isHovering = controller.isDraggingHover.value;
      final borderColor = isHovering
          ? Colors.tealAccent
          : Colors.white.withOpacity(0.1);
      final bgColor = isHovering
          ? Colors.teal.withOpacity(0.1)
          : Colors.white.withOpacity(0.05);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isHovering ? 2 : 1),
        ),
        child: Row(
          children: [
            ElevatedButton.icon(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.pickDirectory,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('导入项目'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                controller.selectedPath.value.isEmpty
                    ? '拖拽文件夹到此处或点击导入'
                    : controller.selectedPath.value,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 估算显示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '预估消耗 (基于文件大小)',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Obx(
                        () => Text(
                          '~${_formatTokenCount(controller.estimatedTokens.value)} Tokens',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // 生成按钮
            Expanded(
              child: SizedBox(
                height: 48,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.fileTreeRoots.isEmpty
                        ? null
                        : controller.generateAndPreview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '生成并预览',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatTokenCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    }
    return count.toString();
  }
}
