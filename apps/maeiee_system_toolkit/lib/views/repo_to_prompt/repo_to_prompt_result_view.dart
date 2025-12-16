import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';
import 'package:maeiee_system_toolkit/views/repo_to_prompt/repo_to_prompt_controller.dart';

class RepoToPromptResultView extends GetView<RepoToPromptController> {
  const RepoToPromptResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: const Text('Prompt 预览'),
        backgroundColor: AppColors.bgPanel,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Obx(
                () => _buildTokenBadge(
                  controller.accurateTokens.value,
                  isAccurate: true,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: RpgContainer(
                style: RpgContainerStyle.panel,
                padding: EdgeInsets.zero,
                child: Obx(
                  () => TextField(
                    controller: TextEditingController(
                      text: controller.generatedContent.value,
                    ),
                    maxLines: null,
                    readOnly: true,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: RpgButton(
                onTap: controller.copyToClipboard,
                icon: Icons.copy,
                label: '复制全部内容',
                type: RpgButtonType.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenBadge(int count, {bool isAccurate = false}) {
    return RpgTag(
      label: '${_formatTokenCount(count)} Tokens',
      color: isAccurate ? AppColors.accentMain : AppColors.textDim,
      icon: Icons.token,
    );
  }

  String _formatTokenCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    }
    return count.toString();
  }
}
