import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // [新增]
import 'package:my_life_rpg/core/data/repository.dart';
import 'package:my_life_rpg/models/quest.dart';

class QuestRepository extends GetxService implements Repository<Quest> {
  final _quests = <Quest>[].obs;
  final _box = GetStorage();
  final _key = 'db_quests';

  @override
  void onInit() {
    super.onInit();
    _loadFromDisk();
  }

  @override
  List<Quest> getAll() => _quests;

  @override
  Quest? getById(String id) {
    return _quests.firstWhereOrNull((q) => q.id == id);
  }

  @override
  void add(Quest item) {
    _quests.add(item);
    _saveToDisk();
  }

  @override
  void update(Quest item) {
    final index = _quests.indexWhere((q) => q.id == item.id);
    if (index != -1) {
      _quests[index] = item;
      _quests.refresh();
      _saveToDisk();
    }
  }

  @override
  void delete(String id) {
    _quests.removeWhere((q) => q.id == id);
    _saveToDisk();
  }

  RxList<Quest> get listenable => _quests;

  // --- Persistence Helpers ---

  void _saveToDisk() {
    final List<Map<String, dynamic>> jsonList = _quests
        .map((q) => q.toJson())
        .toList();
    _box.write(_key, jsonList);
  }

  void _loadFromDisk() {
    final List<dynamic>? stored = _box.read(_key);
    if (stored != null) {
      final list = stored
          .map((e) => Quest.fromJson(e as Map<String, dynamic>))
          .toList();
      _quests.assignAll(list);
    }
  }
}
