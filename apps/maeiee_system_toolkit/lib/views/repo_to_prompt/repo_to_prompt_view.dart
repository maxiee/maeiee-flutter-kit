import 'package:desktop_drop/desktop_drop.dart'; // 引入拖拽库
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cross_file/cross_file.dart'; // DropTarget 返回的是 XFile
import 'package:maeiee_system_toolkit/views/repo_to_prompt/repo_to_prompt_controller.dart';

class RepoToPromptView extends GetView<RepoToPromptController> {
  const RepoToPromptView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('源码转 Prompt')),
      // 使用 DropTarget 包裹整个 Body
      body: DropTarget(
        onDragDone: (detail) {
          // 将 XFile 转换为 String path
          final paths = detail.files.map((e) => e.path).toList();
          controller.handleDropFiles(paths);
          controller.isDraggingHover.value = false;
        },
        onDragEntered: (detail) {
          controller.isDraggingHover.value = true;
        },
        onDragExited: (detail) {
          controller.isDraggingHover.value = false;
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildControlPanel(),
              const SizedBox(height: 16),
              Expanded(child: _buildPreviewArea()),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Obx(() {
      // 拖拽悬停时的视觉反馈
      final isHovering = controller.isDraggingHover.value;
      final borderColor = isHovering
          ? Colors.tealAccent
          : Colors.white.withOpacity(0.1);
      final bgColor = isHovering
          ? Colors.teal.withOpacity(0.1)
          : Colors.white.withOpacity(0.05);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24), // 增加一点内边距，方便拖拽感应
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isHovering ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Icon(
                    isHovering ? Icons.download_rounded : Icons.folder_open,
                    size: 48,
                    color: isHovering ? Colors.tealAccent : Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.pickDirectory,
                    icon: const Icon(Icons.add),
                    label: const Text('选择目录 或 拖拽文件到此处'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              controller.selectedPath.value.isEmpty
                  ? '等待输入...'
                  : '当前: ${controller.selectedPath.value}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (controller.statusMessage.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  controller.statusMessage.value,
                  style: const TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 12,
                  ),
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
            child: TextField(
              controller: TextEditingController(
                text: controller.generatedContent.value,
              ),
              maxLines: null,
              readOnly: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                hintText: 'Prompt 生成区...',
              ),
            ),
          ),
          // 新增：Token 计数器悬浮标
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
                  border: Border.all(color: Colors.tealAccent.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.token, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '~${_formatTokenCount(controller.estimatedTokens.value)} Tokens',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildActionButtons() {
    return SizedBox(
      height: 50,
      child: Obx(
        () => ElevatedButton.icon(
          onPressed: controller.generatedContent.value.isEmpty
              ? null
              : controller.copyToClipboard,
          icon: const Icon(Icons.copy),
          label: const Text('复制 Prompt'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  String _formatTokenCount(int count) {
    if (count >= 10000) {
      // 除以 10000，保留一位小数，例如 12500 -> 1.3w
      return '${(count / 10000).toStringAsFixed(1)}w';
    }
    return count.toString();
  }
}
