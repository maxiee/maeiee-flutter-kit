import 'dart:async';
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

  // 自动同步定时器
  Timer? _autoPullTimer;

  @override
  void onInit() {
    super.onInit();
    LogService.d("GithubSyncService init. Loading config...");
    _loadConfig();

    // 1. 启动时尝试自动 Pull (Cold Start Sync)
    // 延迟一点点，确保其他 Service 就绪
    Future.delayed(const Duration(seconds: 1), () {
      if (config.value.isValid) {
        LogService.i("Auto-Sync: Initial Pull started...");
        pullFromCloud(silent: true);
      }
    });

    // 2. 监听本地保存事件 -> 自动 Push (Auto Save)
    ever(_fileStorage.lastLocalWriteTime, (_) {
      if (config.value.isValid) {
        LogService.i("Auto-Sync: Local change detected. Pushing...");
        pushToCloud(silent: true);
      }
    });

    // 3. 启动定时拉取 (Periodic Pull)
    _startPeriodicPull();
  }

  @override
  void onClose() {
    _autoPullTimer?.cancel();
    super.onClose();
  }

  void _loadConfig() {
    final json = _box.read(_configKey);
    if (json != null) {
      LogService.d("Config loaded from disk: $json"); // 确认读到了
      config.value = SyncConfig.fromJson(json);
    } else {
      LogService.w("No sync config found on disk.");
    }
  }

  Future<void> saveConfig(SyncConfig newConfig) async {
    config.value = newConfig;

    // [修复] 使用 await 确保存入，并打印
    await _box.write(_configKey, newConfig.toJson());
    LogService.i("Config saved to disk.");

    _startPeriodicPull();
  }

  void _startPeriodicPull() {
    _autoPullTimer?.cancel();
    if (config.value.isValid) {
      // 每 5 分钟拉取一次
      _autoPullTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        // 如果正在同步（可能在Push），则跳过本次
        if (!isSyncing.value) {
          LogService.d("Auto-Sync: Periodic Pull triggered.");
          pullFromCloud(silent: true);
        }
      });
    }
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
  /// PULL: silent=true 表示不弹 Snackbar (用于自动同步)
  Future<Result<void>> pullFromCloud({bool silent = false}) async {
    if (!config.value.isValid) return Result.err("Config Invalid");
    isSyncing.value = true;

    try {
      final response = await http.get(_fileUrl, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contentEncoded = data['content'] as String;
        final contentDecoded = utf8.decode(
          base64.decode(contentEncoded.replaceAll('\n', '')),
        );

        // 比较本地和远程是否一致？
        // 简单做法：直接 restore。FileStorageService 会更新内存并写入磁盘，
        // 但 restoreFromString 不会触发 lastLocalWriteTime，所以不会导致死循环 Push。
        await _fileStorage.restoreFromString(contentDecoded);

        _reloadApp();
        _updateLastSync();

        if (!silent) LogService.i("Pull Complete.");
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
  Future<Result<void>> pushToCloud({bool silent = false}) async {
    if (!config.value.isValid) return Result.err("Config Invalid");
    isSyncing.value = true;

    try {
      final localJson = _fileStorage.backupToString();
      final contentBase64 = base64Encode(utf8.encode(localJson));

      // Get SHA first (Optimistic Locking)
      String? sha;
      final getResponse = await http.get(_fileUrl, headers: _headers);
      if (getResponse.statusCode == 200) {
        final data = jsonDecode(getResponse.body);
        sha = data['sha'];
      }

      final body = {
        "message": "Auto-Sync: ${DateTime.now()}",
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
        if (!silent) LogService.i("Push Complete.");
        return Result.ok();
      } else {
        return Result.err("Push Failed: ${putResponse.statusCode}");
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
