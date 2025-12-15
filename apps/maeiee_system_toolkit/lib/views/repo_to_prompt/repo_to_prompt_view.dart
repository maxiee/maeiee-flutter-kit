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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildControlPanel(),
              const SizedBox(height: 16),
              // 新增：文件树区域（限制最大高度，避免占据太多空间）
              Expanded(
                flex: 4, // 权重 4
                child: _buildFileTreeArea(),
              ),
              const SizedBox(height: 16),
              // 预览区域
              Expanded(
                flex: 6, // 权重 6，预览区稍微大一点
                child: _buildPreviewArea(),
              ),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileTreeArea() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // 深色背景
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
                const Spacer(),
                Obx(
                  () => Text(
                    controller.fileTreeRoots.isEmpty ? '' : '点击复选框剔除',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: Obx(() {
              if (controller.fileTreeRoots.isEmpty) {
                return const Center(
                  child: Text('请先选择目录', style: TextStyle(color: Colors.grey)),
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
    // 定义左侧图标
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

    // 如果是目录，使用 ExpansionTile (自定义一点样式以适应紧凑布局)
    if (node.isDirectory) {
      return Obx(
        () => ExpansionTile(
          key: PageStorageKey(node.path), // 保持展开状态
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
          childrenPadding: const EdgeInsets.only(left: 20), // 缩进
          children: node.children
              .map((child) => _buildFileNode(child))
              .toList(),
        ),
      );
    } else {
      // 如果是文件，使用 ListTile
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

  Widget _buildPreviewArea() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: Colors.white.withOpacity(0.05),
                  child: const Text(
                    'Prompt 预览',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(
                      text: controller.generatedContent.value,
                    ),
                    maxLines: null,
                    readOnly: true,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      hintText: '等待生成...',
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (controller.generatedContent.value.isNotEmpty)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '~${_formatTokenCount(controller.estimatedTokens.value)} Tokens',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  String _formatTokenCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    }
    return count.toString();
  }

  Widget _buildActionButtons() {
    return SizedBox(
      height: 48,
      child: Obx(
        () => ElevatedButton.icon(
          onPressed: controller.generatedContent.value.isEmpty
              ? null
              : controller.copyToClipboard,
          icon: const Icon(Icons.copy),
          label: const Text('复制全部 Prompt'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
