import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/controllers/settings_controller.dart';
import 'package:my_life_rpg/views/home/widgets/data_backup_dialog.dart';
import 'package:my_life_rpg/views/settings/widgets/github_config_dialog.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    // 注入控制器
    final c = Get.put(SettingsController());

    return Scaffold(
      backgroundColor: AppColors.bgDarkest,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  RpgIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Get.back(),
                    tooltip: "BACK",
                    color: AppColors.accentMain,
                  ),
                  AppSpacing.gapH16,
                  const Icon(Icons.settings, color: AppColors.accentMain),
                  AppSpacing.gapH12,
                  Text(
                    "SYSTEM CONFIGURATION",
                    style: AppTextStyles.panelHeader.copyWith(
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const RpgDivider(),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // --- Cloud Sync Section ---
                  _buildSectionHeader("CLOUD UPLINK (GITHUB)"),
                  AppSpacing.gapV16,
                  _buildSyncPanel(c),

                  AppSpacing.gapV32,

                  _buildSectionHeader("DATA MATRIX (STORAGE)"),
                  AppSpacing.gapV16,

                  // Storage Info Card
                  RpgContainer(
                    style: RpgContainerStyle.panel,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(
                          () => _buildInfoRow(
                            "FILE PATH",
                            c.filePath.value,
                            canCopy: true,
                          ),
                        ),
                        const RpgDivider(),
                        Obx(
                          () => _buildInfoRow("TOTAL SIZE", c.fileSize.value),
                        ),
                        const RpgDivider(),

                        // Actions
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              RpgButton(
                                label: "REFRESH",
                                type: RpgButtonType.ghost,
                                icon: Icons.refresh,
                                onTap: c.refreshFileInfo,
                                compact: true,
                              ),
                              AppSpacing.gapH12,
                              RpgButton(
                                label: "MANAGE DATA",
                                type: RpgButtonType.primary,
                                icon: Icons.sd_storage,
                                compact: true,
                                onTap: () =>
                                    Get.dialog(const DataBackupDialog()),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  AppSpacing.gapV32,
                  _buildSectionHeader("VERSION INFO"),
                  AppSpacing.gapV16,
                  const Text(
                    "My Life RPG v0.2.0 (Alpha)\nEngine: Flutter 3.x\nProtocol: Single-File JSON",
                    style: TextStyle(
                      color: Colors.grey,
                      fontFamily: 'Courier',
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.accentSystem,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.micro.copyWith(color: Colors.grey),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontFamily: 'Courier',
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          if (canCopy)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                Get.snackbar(
                  "SYSTEM",
                  "Copied to clipboard",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.bgPanel,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 1),
                );
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.copy, size: 14, color: AppColors.textDim),
              ),
            ),
        ],
      ),
    );
  }

  // [新增] 同步面板组件
  Widget _buildSyncPanel(SettingsController c) {
    return RpgContainer(
      style: RpgContainerStyle.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_circle, color: AppColors.accentSystem),
              AppSpacing.gapH12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      final cfg = c.syncService.config.value;
                      if (!cfg.isValid) {
                        return const Text(
                          "UPLINK OFFLINE",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      return Row(
                        children: [
                          Text(
                            "LINKED: ${cfg.owner}/${cfg.repo}",
                            style: const TextStyle(
                              color: AppColors.accentSystem,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Courier',
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Auto 标记
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentSafe.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: AppColors.accentSafe,
                                width: 0.5,
                              ),
                            ),
                            child: const Text(
                              "AUTO",
                              style: TextStyle(
                                fontSize: 8,
                                color: AppColors.accentSafe,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 4),
                    Obx(() {
                      final time = c.syncService.lastSyncTime.value;
                      if (time == null) {
                        return const Text(
                          "Last Sync: NEVER",
                          style: AppTextStyles.micro,
                        );
                      }
                      return Text(
                        "Last Sync: ${time.toString().substring(0, 19)}",
                        style: AppTextStyles.micro,
                      );
                    }),
                  ],
                ),
              ),
              RpgIconButton(
                icon: Icons.edit,
                onTap: () => Get.dialog(const GithubConfigDialog()),
                tooltip: "Configure",
                color: AppColors.accentMain,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sync Actions
          Obx(() {
            if (c.syncService.isSyncing.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(
                    color: AppColors.accentSystem,
                    backgroundColor: Colors.black,
                  ),
                ),
              );
            }
            return Row(
              children: [
                Expanded(
                  child: RpgButton(
                    label: "PULL (DOWNLOAD)",
                    icon: Icons.download,
                    type: RpgButtonType.secondary,
                    onTap: () => _handleSyncAction(c.syncService.pullFromCloud),
                  ),
                ),
                AppSpacing.gapH12,
                Expanded(
                  child: RpgButton(
                    label: "PUSH (UPLOAD)",
                    icon: Icons.upload,
                    type: RpgButtonType.primary,
                    onTap: () => _handleSyncAction(c.syncService.pushToCloud),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _handleSyncAction(Future<dynamic> Function() action) async {
    final result = await action();
    if (result.isSuccess) {
      Get.snackbar(
        "SYNC SUCCESS",
        "Operation completed.",
        backgroundColor: AppColors.accentSafe,
        colorText: Colors.black,
      );
    } else {
      Get.snackbar(
        "SYNC FAILED",
        result.errorMessage ?? "Unknown error",
        backgroundColor: AppColors.accentDanger,
        colorText: Colors.white,
      );
    }
  }
}
