import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // [新增]
import 'package:my_life_rpg/core/data/repository.dart';
import 'package:my_life_rpg/models/project.dart';

class ProjectRepository extends GetxService implements Repository<Project> {
  final _projects = <Project>[].obs;
  final _box = GetStorage(); // [新增] 存储箱
  final _key = 'db_projects'; // [新增] 存储键

  @override
  void onInit() {
    super.onInit();
    _loadFromDisk(); // [新增] 启动时加载
  }

  @override
  List<Project> getAll() => _projects;

  @override
  Project? getById(String id) => _projects.firstWhereOrNull((p) => p.id == id);

  @override
  void add(Project item) {
    _projects.add(item);
    _saveToDisk(); // [新增]
  }

  @override
  void update(Project item) {
    final index = _projects.indexWhere((p) => p.id == item.id);
    if (index != -1) {
      _projects[index] = item; // 这里替换了对象引用
      _projects.refresh(); // 强制通知更新
      _saveToDisk(); // [新增]
    }
  }

  @override
  void delete(String id) {
    _projects.removeWhere((p) => p.id == id);
    _saveToDisk(); // [新增]
  }

  RxList<Project> get listenable => _projects;

  // --- Persistence Helpers ---

  void _saveToDisk() {
    // 序列化：List<Object> -> List<Map>
    final List<Map<String, dynamic>> jsonList = _projects
        .map((p) => p.toJson())
        .toList(); // 需确保 Project 有 toJson
    _box.write(_key, jsonList);
  }

  void _loadFromDisk() {
    final List<dynamic>? stored = _box.read(_key);
    if (stored != null) {
      // 反序列化：List<dynamic> -> List<Project>
      // 必须显式转换类型，防止运行时错误
      final list = stored
          .map((e) => Project.fromJson(e as Map<String, dynamic>))
          .toList();
      _projects.assignAll(list);
    }
  }
}
