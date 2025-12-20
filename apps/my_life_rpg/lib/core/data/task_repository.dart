import 'package:my_life_rpg/core/constants.dart';
import 'package:my_life_rpg/core/data/base_repository.dart';
import 'package:my_life_rpg/models/task.dart';

class TaskRepository extends BaseRepository<Task> {
  @override
  String get storageKey => Constants.keyTasks;

  @override
  Task fromJson(Map<String, dynamic> json) => Task.fromJson(json);
}
