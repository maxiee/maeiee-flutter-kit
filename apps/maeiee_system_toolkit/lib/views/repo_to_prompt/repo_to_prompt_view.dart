import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:maeiee_system_toolkit/views/repo_to_prompt/repo_to_prompt_controller.dart';

class RepoToPromptView extends GetView<RepoToPromptController> {
  const RepoToPromptView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('源码转 Prompt')),
      body: Padding(
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
    );
  }

  Widget _buildControlPanel() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.pickDirectory,
              icon: const Icon(Icons.folder_open),
              label: const Text('选择仓库目录'),
            ),
            const SizedBox(height: 8),
            Text(
              controller.selectedPath.value.isEmpty
                  ? '未选择目录'
                  : '已选: ${controller.selectedPath.value}',
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
      ),
    );
  }

  Widget _buildPreviewArea() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return Container(
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
            hintText: '生成的内容将显示在这里...',
          ),
        ),
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
          label: const Text('复制到剪贴板'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
