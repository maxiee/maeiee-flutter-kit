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

  /// 初始化服务：定位文件并加载数据到内存
  Future<FileStorageService> init() async {
    await _initFile();
    await load();
    return this;
  }

  Future<void> _initFile() async {
    // 获取应用文档目录
    final dir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${dir.path}/MyLifeRPG');
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    _file = File('${targetDir.path}/$fileName');

    // 如果文件不存在，创建一个空的 JSON 对象
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
      // 出错时不覆盖内存，防止数据丢失
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
    // 1. 对 Key 进行排序
    final sortedKeys = _memoryCache.keys.toList()..sort();

    // 2. 构建排序后的 Map
    final sortedMap = {for (var k in sortedKeys) k: _memoryCache[k]};

    // 3. 序列化 (2空格缩进)
    return const JsonEncoder.withIndent('  ').convert(sortedMap);
  }

  /// [导入] 从外部 JSON 字符串恢复数据
  /// 这将覆盖当前内存和磁盘文件
  Future<void> restoreFromString(String jsonContent) async {
    if (!_isReady || _file == null) throw "Storage not initialized";

    // 1. 校验 JSON 格式
    final dynamic decoded = jsonDecode(jsonContent);
    if (decoded is! Map<String, dynamic>) {
      throw "Invalid format: Root must be a JSON object";
    }

    // 2. 更新内存
    _memoryCache.value = decoded;

    // 3. 立即写入磁盘 (不防抖，确保原子性)
    await _file!.writeAsString(jsonContent, flush: true);
    LogService.i("System restored from external protocol.");
  }

  /// [重置] 清空所有数据
  Future<void> clearAll() async {
    if (!_isReady || _file == null) return;

    _memoryCache.clear();
    await _file!.writeAsString('{}', flush: true);
    LogService.w("System performed FACTORY RESET.");
  }

  // --- 内部写入机制 ---

  bool _writePending = false;

  /// 防抖写入：避免频繁 IO 操作
  void _debounceWrite() async {
    if (_writePending || _file == null) return;
    _writePending = true;

    // 延迟 2秒，合并多次写入请求
    await Future.delayed(const Duration(seconds: 2));

    try {
      final jsonStr = backupToString(); // 复用导出逻辑生成字符串
      await _file!.writeAsString(jsonStr, flush: true);
      // LogService.d("Core dump auto-saved."); // 调试用，生产环境可注释
    } catch (e) {
      LogService.e("Auto-save failed: $e");
    } finally {
      _writePending = false;
    }
  }
}
