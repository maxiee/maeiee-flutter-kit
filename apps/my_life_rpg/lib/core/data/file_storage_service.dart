import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:my_life_rpg/core/utils/logger.dart';

class FileStorageService extends GetxService {
  static const String fileName = 'my_life_core.json';

  // 内存缓存：Key 是存储键（如 db_tasks），Value 是 List 数据
  final _memoryCache = <String, dynamic>{}.obs;

  File? _file;
  bool _isReady = false;

  // 暴露文件对象供设置页面查看信息
  File? get file => _file;

  // 只有当"本地"修改导致文件写入成功时，该时间戳才会更新
  // GithubSyncService 将监听这个变量来触发自动 Push
  final lastLocalWriteTime = Rxn<DateTime>();

  /// 初始化服务：定位文件并加载数据到内存
  Future<FileStorageService> init() async {
    await _initFile();
    await load();
    return this;
  }

  Future<void> _initFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${dir.path}/MyLifeRPG');
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    _file = File('${targetDir.path}/$fileName');

    if (!_file!.existsSync()) {
      await _file!.writeAsString('{}');
    }
    _isReady = true;
    LogService.i("Storage initialized at: ${_file!.path}");
  }

  /// 从磁盘加载数据到内存
  Future<void> load() async {
    if (!_isReady || _file == null) return;
    try {
      final content = await _file!.readAsString();
      if (content.isEmpty) {
        _memoryCache.value = {};
        return;
      }
      _memoryCache.value = jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      LogService.e("Critical: Failed to load core file: $e");
    }
  }

  // --- 核心 CRUD 接口 (供 Repository 调用) ---

  /// 读取指定 Key 的数据
  List<dynamic> read(String key) {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key] as List<dynamic>;
    }
    return [];
  }

  /// 保存数据到指定 Key (带防抖写入)
  Future<void> save(String key, List<dynamic> data) async {
    _memoryCache[key] = data;
    _debounceWrite();
  }

  // --- 备份与恢复接口 (供 DataBackupDialog 调用) ---

  /// [导出] 将当前内存中的所有数据序列化为 Pretty JSON 字符串
  /// 包含了排序逻辑，确保 Git Diff 友好
  String backupToString() {
    final sortedKeys = _memoryCache.keys.toList()..sort();
    final sortedMap = {for (var k in sortedKeys) k: _memoryCache[k]};
    return const JsonEncoder.withIndent('  ').convert(sortedMap);
  }

  /// [导入] 从外部 JSON 字符串恢复数据
  /// 这将覆盖当前内存和磁盘文件
  Future<void> restoreFromString(String jsonContent) async {
    if (!_isReady || _file == null) throw "Storage not initialized";

    final dynamic decoded = jsonDecode(jsonContent);
    if (decoded is! Map<String, dynamic>) {
      throw "Invalid format: Root must be a JSON object";
    }

    _memoryCache.value = decoded;
    await _file!.writeAsString(jsonContent, flush: true);
    LogService.i("System restored from external protocol.");
  }

  /// [重置] 清空所有数据
  Future<void> clearAll() async {
    if (!_isReady || _file == null) return;
    _memoryCache.clear();
    await _file!.writeAsString('{}', flush: true);
    LogService.w("System performed FACTORY RESET.");
    // 清空也被视为本地操作，应该同步上去（变成空文件）
    lastLocalWriteTime.value = DateTime.now();
  }

  // --- 内部写入机制 ---

  bool _writePending = false;

  /// 防抖写入：避免频繁 IO 操作
  void _debounceWrite() async {
    if (_writePending || _file == null) return;
    _writePending = true;
    await Future.delayed(const Duration(seconds: 2));

    try {
      final jsonStr = backupToString();
      await _file!.writeAsString(jsonStr, flush: true);

      // 标记本地写入完成，通知监听者
      lastLocalWriteTime.value = DateTime.now();
    } catch (e) {
      LogService.e("Auto-save failed: $e");
    } finally {
      _writePending = false;
    }
  }
}
