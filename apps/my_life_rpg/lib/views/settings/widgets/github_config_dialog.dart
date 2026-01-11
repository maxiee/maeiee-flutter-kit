import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/models/sync_config.dart';
import 'package:my_life_rpg/services/github_sync_service.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';

class GithubConfigDialog extends StatefulWidget {
  const GithubConfigDialog({super.key});

  @override
  State<GithubConfigDialog> createState() => _GithubConfigDialogState();
}

class _GithubConfigDialogState extends State<GithubConfigDialog> {
  final GithubSyncService _sync = Get.find();

  late TextEditingController _tokenCtrl;
  late TextEditingController _ownerCtrl;
  late TextEditingController _repoCtrl;
  late TextEditingController _pathCtrl;

  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    final cfg = _sync.config.value;
    _tokenCtrl = TextEditingController(text: cfg.token);
    _ownerCtrl = TextEditingController(text: cfg.owner);
    _repoCtrl = TextEditingController(text: cfg.repo);
    _pathCtrl = TextEditingController(text: cfg.path);
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _ownerCtrl.dispose();
    _repoCtrl.dispose();
    _pathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RpgDialog(
      title: "UPLINK CONFIGURATION",
      icon: Icons.cloud_sync,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "GitHub Personal Access Token (Repo Scope)",
              style: AppTextStyles.micro,
            ),
            AppSpacing.gapV8,
            RpgInput(controller: _tokenCtrl, hint: "ghp_xxxxxxxxxxxx"),
            AppSpacing.gapV16,

            Row(
              children: [
                Expanded(
                  child: RpgInput(
                    label: "OWNER",
                    controller: _ownerCtrl,
                    hint: "username",
                  ),
                ),
                AppSpacing.gapH12,
                Expanded(
                  child: RpgInput(
                    label: "REPO",
                    controller: _repoCtrl,
                    hint: "my-life-data",
                  ),
                ),
              ],
            ),
            AppSpacing.gapV16,
            RpgInput(
              label: "FILE PATH",
              controller: _pathCtrl,
              hint: "data/core.json",
            ),
            AppSpacing.gapV24,

            if (_isTesting)
              const Center(
                child: CircularProgressIndicator(color: AppColors.accentMain),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  RpgButton(
                    label: "TEST CONNECTION",
                    type: RpgButtonType.ghost,
                    onTap: _testConnection,
                  ),
                  AppSpacing.gapH12,
                  RpgButton(
                    label: "SAVE CONFIG",
                    type: RpgButtonType.primary,
                    onTap: _save,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _testConnection() async {
    setState(() => _isTesting = true);
    // 临时构建 Config 对象进行测试
    final tempConfig = SyncConfig(
      token: _tokenCtrl.text.trim(),
      owner: _ownerCtrl.text.trim(),
      repo: _repoCtrl.text.trim(),
      path: _pathCtrl.text.trim(),
    );

    // 保存到 Service (暂时的，为了让 Service 用这个配置测试)
    await _sync.saveConfig(tempConfig);

    final result = await _sync.testConnection();
    setState(() => _isTesting = false);

    if (result.isSuccess) {
      Get.snackbar(
        "CONNECTION ESTABLISHED",
        result.data ?? "OK",
        backgroundColor: AppColors.accentSafe,
        colorText: Colors.black,
      );
    } else {
      Get.snackbar(
        "CONNECTION FAILED",
        result.errorMessage ?? "Error",
        backgroundColor: AppColors.accentDanger,
        colorText: Colors.white,
      );
    }
  }

  void _save() {
    final newConfig = SyncConfig(
      token: _tokenCtrl.text.trim(),
      owner: _ownerCtrl.text.trim(),
      repo: _repoCtrl.text.trim(),
      path: _pathCtrl.text.trim(),
    );

    _sync.saveConfig(newConfig);
    Get.back();
    Get.snackbar(
      "SYSTEM",
      "Uplink Configuration Saved.",
      backgroundColor: Colors.black,
      colorText: Colors.white,
    );
  }
}
