import 'package:get/get.dart';
import 'package:my_life_rpg/core/data/file_storage_service.dart';
import 'package:my_life_rpg/core/data/repository.dart';
import 'package:my_life_rpg/models/serializable.dart';

/// [BaseRepository]
/// 通用的持久化仓储基类。
/// T: 数据模型类型，必须实现 Serializable 接口。
abstract class BaseRepository<T extends Serializable> extends GetxService
    implements Repository<T> {
  String get storageKey;
  T fromJson(Map<String, dynamic> json);

  final _items = <T>[].obs;
  // 依赖注入获取 Storage
  late FileStorageService _storage;

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<FileStorageService>();
    _loadFromDisk();
  }

  RxList<T> get listenable => _items;

  @override
  List<T> getAll() => _items;

  @override
  T? getById(String id) => _items.firstWhereOrNull((e) => e.id == id);

  @override
  void add(T item) {
    _items.add(item);
    _saveToDisk();
  }

  @override
  void update(T item) {
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      _items[index] = item;
      _items.refresh();
      _saveToDisk();
    }
  }

  @override
  void delete(String id) {
    _items.removeWhere((e) => e.id == id);
    _saveToDisk();
  }

  void _saveToDisk() {
    // 关键优化：写入前先按照 ID 排序，确保 List 顺序在 Git 中稳定
    // 避免 [A, B] 变成 [B, A] 造成无谓的 Diff
    // 注意：这里我们排序的是 _items 的副本用于存储，不影响运行时顺序（如果运行时有特殊排序需求）
    final sortedList = List<T>.from(_items)
      ..sort((a, b) => a.id.compareTo(b.id));

    final List<Map<String, dynamic>> jsonList = sortedList
        .map((e) => e.toJson())
        .toList();

    _storage.save(storageKey, jsonList);
  }

  void _loadFromDisk() {
    final List<dynamic> stored = _storage.read(storageKey);
    if (stored.isNotEmpty) {
      final list = stored
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
      _items.assignAll(list);
    }
  }
}
