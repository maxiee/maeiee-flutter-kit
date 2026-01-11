import 'package:get/get.dart';
import 'package:my_life_rpg/core/data/file_storage_service.dart';

class SettingsController extends GetxController {
  final FileStorageService _storage = Get.find();

  final filePath = 'UNKNOWN'.obs;
  final fileSize = '0 KB'.obs;

  @override
  void onInit() {
    super.onInit();
    refreshFileInfo();
  }

  Future<void> refreshFileInfo() async {
    final f = _storage.file;
    if (f != null && f.existsSync()) {
      filePath.value = f.path;

      final len = await f.length();
      if (len < 1024) {
        fileSize.value = "$len B";
      } else if (len < 1024 * 1024) {
        fileSize.value = "${(len / 1024).toStringAsFixed(2)} KB";
      } else {
        fileSize.value = "${(len / (1024 * 1024)).toStringAsFixed(2)} MB";
      }
    } else {
      filePath.value = "NOT MOUNTED";
      fileSize.value = "N/A";
    }
  }
}
