import 'package:get/get.dart';
import 'package:my_life_rpg/core/data/repository.dart';
import 'package:my_life_rpg/models/quest.dart';

class QuestRepository extends GetxService implements Repository<Quest> {
  // 数据源 (这里是内存，未来可以是 SQLite 的 DAO)
  final _quests = <Quest>[].obs;

  @override
  List<Quest> getAll() => _quests;

  @override
  Quest? getById(String id) {
    return _quests.firstWhereOrNull((q) => q.id == id);
  }

  @override
  void add(Quest item) {
    _quests.add(item);
  }

  @override
  void update(Quest item) {
    final index = _quests.indexWhere((q) => q.id == item.id);
    if (index != -1) {
      _quests[index] = item;
    }
  }

  @override
  void delete(String id) {
    _quests.removeWhere((q) => q.id == id);
  }

  // 暴露 observable 给 Service 用于监听，这是 GetX 的特性
  RxList<Quest> get listenable => _quests;
}
