import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';
import 'package:my_life_rpg/core/constants.dart';

class DataBackupDialog extends StatelessWidget {
  const DataBackupDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return RpgDialog(
      title: "SYSTEM CORE DUMP",
      icon: Icons.sd_storage,
      onCancel: () => Get.back(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "MANUAL OVERRIDE PROTOCOLS",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          AppSpacing.gapV16,

          _buildActionBtn(
            "EXPORT DATABASE (CLIPBOARD)",
            Icons.copy,
            AppColors.accentMain,
            _exportData,
          ),
          AppSpacing.gapV8,
          _buildActionBtn(
            "IMPORT DATABASE (OVERWRITE)",
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

  void _exportData() {
    final box = GetStorage();
    final tasks = box.read(Constants.keyTasks);
    final projects = box.read(Constants.keyProjects);

    final dump = {
      'timestamp': DateTime.now().toIso8601String(),
      'projects': projects,
      'tasks': tasks,
    };

    final jsonStr = jsonEncode(dump);
    Clipboard.setData(ClipboardData(text: jsonStr));
    Get.snackbar(
      "SYSTEM",
      "Core dump copied to clipboard.",
      backgroundColor: Colors.black,
      colorText: AppColors.accentMain,
    );
  }

  Future<void> _importData() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;

    try {
      final json = jsonDecode(data!.text!) as Map<String, dynamic>;
      if (!json.containsKey('tasks')) throw "Invalid Dump Format";

      // 警告
      Get.defaultDialog(
        title: "WARNING: OVERWRITE",
        content: const Text(
          "This will replace ALL current data.\nProceed?",
          textAlign: TextAlign.center,
        ),
        confirmTextColor: Colors.white,
        onConfirm: () {
          final box = GetStorage();
          if (json['projects'] != null)
            box.write(Constants.keyProjects, json['projects']);
          if (json['tasks'] != null)
            box.write(Constants.keyTasks, json['tasks']);

          // 强制重启 App 逻辑比较麻烦，不如让用户手动重启
          Get.back(); // close dialog
          Get.back(); // close backup panel
          Get.snackbar(
            "SYSTEM",
            "Data injected. PLEASE RESTART APP.",
            duration: const Duration(seconds: 5),
            backgroundColor: AppColors.accentSystem,
            colorText: Colors.black,
          );
        },
      );
    } catch (e) {
      Get.snackbar(
        "ERROR",
        "Corrupted Data Stream: $e",
        backgroundColor: Colors.black,
        colorText: Colors.red,
      );
    }
  }

  void _factoryReset() {
    Get.defaultDialog(
      title: "CONFIRM NUKE",
      content: const Text(
        "IRREVERSIBLE DATA LOSS.\nARE YOU SURE?",
        style: TextStyle(color: Colors.red),
      ),
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        final box = GetStorage();
        box.erase();
        Get.back();
        Get.back();
        Get.snackbar(
          "SYSTEM",
          "Memory wiped. Rebooting...",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      },
    );
  }
}
