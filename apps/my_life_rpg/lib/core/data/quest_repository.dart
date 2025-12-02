import 'package:my_life_rpg/core/data/base_repository.dart';
import 'package:my_life_rpg/models/quest.dart';

class QuestRepository extends BaseRepository<Quest> {
  @override
  String get storageKey => 'db_quests';

  @override
  Quest fromJson(Map<String, dynamic> json) => Quest.fromJson(json);
}
