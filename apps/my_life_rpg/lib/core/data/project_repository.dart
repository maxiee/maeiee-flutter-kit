import 'package:get/get.dart';
import 'package:my_life_rpg/core/data/repository.dart';
import 'package:my_life_rpg/models/project.dart';

class ProjectRepository extends GetxService implements Repository<Project> {
  final _projects = <Project>[].obs;

  @override
  List<Project> getAll() => _projects;

  @override
  Project? getById(String id) => _projects.firstWhereOrNull((p) => p.id == id);

  @override
  void add(Project item) => _projects.add(item);

  @override
  void update(Project item) {
    final index = _projects.indexWhere((p) => p.id == item.id);
    if (index != -1) _projects[index] = item;
  }

  @override
  void delete(String id) => _projects.removeWhere((p) => p.id == id);

  RxList<Project> get listenable => _projects;
}
