import 'package:get/get.dart';
import 'package:my_life_rpg/core/data/file_storage_service.dart';
import 'package:my_life_rpg/services/github_sync_service.dart';

class SettingsController extends GetxController {
  final FileStorageService _storage = Get.find();
  final GithubSyncService syncService = Get.find();

  final filePath = 'UNKNOWN'.obs;
  final fileSize = '0 KB'.obs;

  @override
  void onInit() {
    super.onInit();
    refreshFileInfo();
  }

  Future<void> refreshFileInfo() async {
    final f = _storage.file;

    // 1. 检查 Service 是否就绪 (File 对象是否为 null)
    if (f == null) {
      filePath.value = "SERVICE NOT READY (File is null)";
      fileSize.value = "N/A";
      return;
    }

    // 2. 显示路径 (无论是否存在)
    // macOS 路径通常很长，这里显示绝对路径
    filePath.value = f.path;

    // 3. 检查文件物理状态
    final exists = f.existsSync();

    if (exists) {
      try {
        final len = await f.length();
        if (len < 1024) {
          fileSize.value = "$len B";
        } else if (len < 1024 * 1024) {
          fileSize.value = "${(len / 1024).toStringAsFixed(2)} KB";
        } else {
          fileSize.value = "${(len / (1024 * 1024)).toStringAsFixed(2)} MB";
        }
      } catch (e) {
        fileSize.value = "READ ERROR";
      }
    } else {
      // 文件对象不为空，但磁盘上找不到 -> 加上后缀提示
      filePath.value = "${f.path} (NOT FOUND ON DISK)";
      fileSize.value = "0 B (New File)";
    }
  }
}
