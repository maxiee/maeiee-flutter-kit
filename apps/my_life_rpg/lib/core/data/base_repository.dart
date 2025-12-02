import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:my_life_rpg/core/data/repository.dart';
import 'package:my_life_rpg/models/serializable.dart';

/// [BaseRepository]
/// 通用的持久化仓储基类。
/// T: 数据模型类型，必须实现 Serializable 接口。
abstract class BaseRepository<T extends Serializable> extends GetxService
    implements Repository<T> {
  // 抽象属性：由子类指定存储键和工厂方法
  String get storageKey;
  T fromJson(Map<String, dynamic> json);

  final _items = <T>[].obs;
  final _box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _loadFromDisk();
  }

  // --- 暴露给 Service 的数据源 ---
  RxList<T> get listenable => _items;

  // --- Repository 接口实现 ---

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
      _items.refresh(); // 强制触发 Rx 更新
      _saveToDisk();
    }
  }

  @override
  void delete(String id) {
    _items.removeWhere((e) => e.id == id);
    _saveToDisk();
  }

  // --- 内部持久化逻辑 ---

  void _saveToDisk() {
    // 序列化：List<T> -> List<Map>
    final List<Map<String, dynamic>> jsonList = _items
        .map((e) => e.toJson())
        .toList();
    _box.write(storageKey, jsonList);
  }

  void _loadFromDisk() {
    final List<dynamic>? stored = _box.read(storageKey);
    if (stored != null) {
      // 反序列化：List<Map> -> List<T>
      // 使用子类提供的 fromJson 工厂方法
      final list = stored
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
      _items.assignAll(list);
    }
  }
}
