import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:my_life_rpg/core/data/file_storage_service.dart';
import 'package:my_life_rpg/core/utils/logger.dart';
import 'package:my_life_rpg/core/utils/result.dart';
import 'package:my_life_rpg/models/sync_config.dart';
import 'package:my_life_rpg/services/task_service.dart';

class GithubSyncService extends GetxService {
  final FileStorageService _fileStorage = Get.find();
  final _box = GetStorage(); // 用于存 Token 等配置，不存数据
  final String _configKey = 'github_sync_config';

  final config = SyncConfig().obs;
  final isSyncing = false.obs;
  final lastSyncTime = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    _loadConfig();
  }

  void _loadConfig() {
    final json = _box.read(_configKey);
    if (json != null) {
      config.value = SyncConfig.fromJson(json);
    }
  }

  Future<void> saveConfig(SyncConfig newConfig) async {
    config.value = newConfig;
    await _box.write(_configKey, newConfig.toJson());
  }

  // --- API Helpers ---

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${config.value.token}',
    'Accept': 'application/vnd.github.v3+json',
    'Content-Type': 'application/json',
  };

  Uri get _fileUrl => Uri.parse(
    'https://api.github.com/repos/${config.value.owner}/${config.value.repo}/contents/${config.value.path}',
  );

  // --- Core Actions ---

  /// 测试连接：尝试获取 Repo 信息或文件 Metadata
  Future<Result<String>> testConnection() async {
    if (!config.value.isValid) return Result.err("Config incomplete");

    try {
      final response = await http.get(_fileUrl, headers: _headers);

      if (response.statusCode == 200) {
        return Result.ok("Connection Successful! File found.");
      } else if (response.statusCode == 404) {
        return Result.ok(
          "Connection Successful! File not created yet (Will be created on Push).",
        );
      } else {
        return Result.err(
          "GitHub API Error: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      return Result.err("Network Error: $e");
    }
  }

  /// PULL: 从 GitHub 下载 -> 覆盖本地
  Future<Result<void>> pullFromCloud() async {
    if (!config.value.isValid) return Result.err("Config Invalid");
    isSyncing.value = true;

    try {
      final response = await http.get(_fileUrl, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contentEncoded = data['content'] as String;
        // GitHub API 返回的是 Base64 编码的内容
        // 注意处理换行符
        final contentDecoded = utf8.decode(
          base64.decode(contentEncoded.replaceAll('\n', '')),
        );

        // 写入本地
        await _fileStorage.restoreFromString(contentDecoded);

        // 刷新业务层
        _reloadApp();

        _updateLastSync();
        return Result.ok();
      } else {
        return Result.err("Pull Failed: ${response.statusCode}");
      }
    } catch (e) {
      LogService.e("Pull Error: $e");
      return Result.err(e.toString());
    } finally {
      isSyncing.value = false;
    }
  }

  /// PUSH: 获取本地 -> 获取远程 SHA (如果存在) -> 上传
  Future<Result<void>> pushToCloud() async {
    if (!config.value.isValid) return Result.err("Config Invalid");
    isSyncing.value = true;

    try {
      // 1. 获取本地数据
      final localJson = _fileStorage.backupToString();
      final contentBase64 = base64Encode(utf8.encode(localJson));

      // 2. 获取远程文件的 SHA (Update 需要提供 SHA，Create 不需要)
      String? sha;
      final getResponse = await http.get(_fileUrl, headers: _headers);
      if (getResponse.statusCode == 200) {
        final data = jsonDecode(getResponse.body);
        sha = data['sha'];
      }

      // 3. 构建 PUT 请求
      final body = {
        "message": "Sync from MyLifeRPG (Android/PC) at ${DateTime.now()}",
        "content": contentBase64,
        if (sha != null) "sha": sha,
      };

      final putResponse = await http.put(
        _fileUrl,
        headers: _headers,
        body: jsonEncode(body),
      );

      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        _updateLastSync();
        return Result.ok();
      } else {
        return Result.err(
          "Push Failed: ${putResponse.statusCode} - ${putResponse.body}",
        );
      }
    } catch (e) {
      LogService.e("Push Error: $e");
      return Result.err(e.toString());
    } finally {
      isSyncing.value = false;
    }
  }

  void _updateLastSync() {
    lastSyncTime.value = DateTime.now();
  }

  void _reloadApp() {
    // 通知 TaskService 刷新 (假设 TaskService 已实现 notifyUpdate 或类似逻辑)
    // 实际上这里最稳妥的是像 BackupDialog 那样提示用户或尝试热重载数据
    try {
      Get.find<TaskService>().notifyUpdate();
    } catch (e) {
      print("Service reload warning: $e");
    }
  }
}
