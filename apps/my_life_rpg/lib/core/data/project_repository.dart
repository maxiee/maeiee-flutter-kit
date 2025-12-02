import 'package:my_life_rpg/core/data/base_repository.dart';
import 'package:my_life_rpg/models/project.dart';

class ProjectRepository extends BaseRepository<Project> {
  @override
  String get storageKey => 'db_projects';

  @override
  Project fromJson(Map<String, dynamic> json) => Project.fromJson(json);
}
