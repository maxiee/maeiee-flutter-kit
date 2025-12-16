import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: const Text('Maeiee Toolkit'),
        backgroundColor: AppColors.bgPanel,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildToolCard(
              title: '源码转 Prompt',
              description: '读取仓库文件，生成便于 AI 理解的 Prompt',
              icon: Icons.code,
              onTap: () => Get.toNamed('/repo_to_prompt'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return RpgContainer(
      style: RpgContainerStyle.card,
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: AppColors.accentMain),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.panelHeader.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
