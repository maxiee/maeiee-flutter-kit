import 'package:my_life_rpg/core/data/base_repository.dart';
import 'package:my_life_rpg/models/task.dart';

class QuestRepository extends BaseRepository<Task> {
  @override
  String get storageKey => 'db_quests';

  @override
  Task fromJson(Map<String, dynamic> json) => Task.fromJson(json);
}
