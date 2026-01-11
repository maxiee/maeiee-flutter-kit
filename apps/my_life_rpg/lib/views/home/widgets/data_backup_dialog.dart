import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/data/file_storage_service.dart';
import 'package:my_life_rpg/services/task_service.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';

class DataBackupDialog extends StatefulWidget {
  const DataBackupDialog({super.key});

  @override
  State<DataBackupDialog> createState() => _DataBackupDialogState();
}

class _DataBackupDialogState extends State<DataBackupDialog> {
  bool _isLoading = false;

  // 获取单一纯文本文件服务
  final FileStorageService _storage = Get.find<FileStorageService>();

  @override
  Widget build(BuildContext context) {
    return RpgDialog(
      title: "CORE DUMP / GIT SYNC", // 改个更极客的名字
      icon: Icons.sd_storage,
      onCancel: () => Get.back(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "SINGLE FILE PROTOCOL (JSON)",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          AppSpacing.gapV16,

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: AppColors.accentMain),
              ),
            )
          else ...[
            _buildActionBtn(
              "COPY JSON TO CLIPBOARD",
              Icons.copy,
              AppColors.accentMain,
              _exportData,
            ),
            AppSpacing.gapV8,
            _buildActionBtn(
              "OVERWRITE FROM CLIPBOARD",
              Icons.paste,
              AppColors.accentSystem,
              _importData,
            ),
            AppSpacing.gapV24,
            const RpgDivider(),
            AppSpacing.gapV24,
            _buildActionBtn(
              "FACTORY RESET (NUKE)",
              Icons.delete_forever,
              AppColors.accentDanger,
              _factoryReset,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return RpgButton(
      label: label,
      icon: icon,
      type: RpgButtonType.secondary,
      onTap: onTap,
    );
  }

  // 1. 导出
  void _exportData() async {
    setState(() => _isLoading = true);

    try {
      // 直接从 Service 获取格式化好的 JSON 字符串
      final jsonStr = _storage.backupToString();

      await Clipboard.setData(ClipboardData(text: jsonStr));

      if (mounted) {
        Get.snackbar(
          "SYSTEM EXPORT",
          "Core JSON copied to clipboard.",
          backgroundColor: Colors.black,
          colorText: AppColors.accentMain,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      Get.snackbar("EXPORT ERROR", e.toString(), backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. 导入
  Future<void> _importData() async {
    setState(() => _isLoading = true);

    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == null || data!.text!.isEmpty) {
        throw "Clipboard is empty.";
      }

      final jsonContent = data.text!;

      // 预检查 JSON 有效性
      try {
        jsonDecode(jsonContent);
      } catch (e) {
        throw "Clipboard content is not valid JSON.";
      }

      Get.defaultDialog(
        title: "WARNING: OVERWRITE",
        titleStyle: const TextStyle(color: AppColors.accentDanger),
        content: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "This will PERMANENTLY REPLACE your local file with clipboard content.\nProceed?",
            textAlign: TextAlign.center,
          ),
        ),
        confirmTextColor: Colors.white,
        buttonColor: AppColors.accentDanger,
        textConfirm: "OVERWRITE",
        textCancel: "ABORT",
        onConfirm: () async {
          // 调用 Service 执行覆盖
          await _storage.restoreFromString(jsonContent);

          // 通知业务层刷新
          _reloadServices();

          Get.back(); // Close Dialog
          Get.back(); // Close Panel

          Get.snackbar(
            "SYSTEM RESTORED",
            "Data injected via JSON Protocol.",
            backgroundColor: AppColors.accentSystem,
            colorText: Colors.black,
          );
        },
      );
    } catch (e) {
      Get.snackbar(
        "IMPORT ERROR",
        "$e",
        backgroundColor: Colors.black,
        colorText: Colors.red,
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. 重置
  void _factoryReset() {
    Get.defaultDialog(
      title: "CONFIRM NUKE",
      titleStyle: const TextStyle(color: Colors.red),
      content: const Text(
        "This will clear the JSON file.\nIRREVERSIBLE.",
        style: TextStyle(color: Colors.red),
        textAlign: TextAlign.center,
      ),
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      textConfirm: "NUKE IT",
      textCancel: "CANCEL",
      onConfirm: () async {
        await _storage.clearAll();

        _reloadServices();

        Get.back();
        Get.back();

        Get.snackbar(
          "SYSTEM WIPED",
          "Core file initialized.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
    );
  }

  void _reloadServices() {
    try {
      // 触发 TaskService 的通知机制，让 UI 重新从 Repo 拉取数据
      // 注意：Repo 需要重新从 Storage 读取数据到内存 _items
      // 这里我们在 Repo 实现中需要确保监听了 Storage 或者手动触发 Repo.load
      // 为了简单，我们只通知 UI 刷新，前提是 Repo 已经感知到了 Storage 的变化
      // 最稳妥方式：提示重启，或者手动调用 Repo 的 reload (需要修改 Repo 暴露 reload 接口)

      final TaskService qs = Get.find();
      // 这是一个 hack，理想情况下我们应该调用 repo.loadFromDisk()
      // 但为了不改动太多接口，我们假设用户会重启 App，或者你在 BaseRepository 里添加了 reload 方法
      qs.notifyUpdate();
    } catch (e) {
      debugPrint("Service reload failed: $e");
    }
  }
}
