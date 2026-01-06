import 'package:get/get.dart';
import 'package:my_life_rpg/controllers/mission_controller.dart';
import 'package:my_life_rpg/models/project.dart';
import 'package:my_life_rpg/models/task.dart';
import 'package:my_life_rpg/services/task_service.dart';
import 'package:my_life_rpg/views/session/session_binding.dart';
import 'package:my_life_rpg/views/session/session_view.dart';

enum ResultType { project, task, create }

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final ResultType type;
  final dynamic data;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.data,
  });
}

class CommandPaletteController extends GetxController {
  final TaskService _qs = Get.find();
  final MissionController _mc = Get.find();

  final searchText = ''.obs;
  final results = <SearchResult>[].obs;

  // 监听输入变化
  void onSearchChanged(String query) {
    searchText.value = query;
    if (query.isEmpty) {
      results.clear();
      return;
    }

    final queryLower = query.toLowerCase();
    final List<SearchResult> temp = [];

    // 1. Search Projects
    for (var p in _qs.projects) {
      if (p.title.toLowerCase().contains(queryLower)) {
        temp.add(
          SearchResult(
            id: p.id,
            title: p.title,
            subtitle: "PROJECT / SECTOR",
            type: ResultType.project,
            data: p,
          ),
        );
      }
    }

    // 2. Search Tasks (Active only or All? Let's search All including completed)
    for (var t in _qs.tasks) {
      if (t.title.toLowerCase().contains(queryLower)) {
        temp.add(
          SearchResult(
            id: t.id,
            title: t.title,
            subtitle: t.isCompleted ? "COMPLETED" : "ACTIVE TASK",
            type: ResultType.task,
            data: t,
          ),
        );
      }
    }

    results.assignAll(temp);
  }

  // 执行跳转或创建
  void onSelect(SearchResult item) {
    Get.back(); // 关闭弹窗

    if (item.type == ResultType.project) {
      _jumpToProject(item.data as Project);
    } else if (item.type == ResultType.task) {
      _jumpToTask(item.data as Task);
    }
  }

  void quickCreate() {
    final title = searchText.value.trim();
    if (title.isEmpty) return;

    Get.back(); // 关闭弹窗

    // 快速创建到 Inbox
    _qs.addNewTask(
      title: title,
      type: TaskType.todo,
      // 无 Project，无 Direction -> Inbox
    );

    // 自动跳转到 Inbox 视图以便用户看到刚才创建的
    _mc.setGlobalFilter('inbox');

    Get.snackbar("SYSTEM", "Task '$title' created in INBOX.");
  }

  void _jumpToProject(Project p) {
    // 1. 设置 Direction
    if (p.directionId != null) {
      _mc.selectDirection(p.directionId);
    } else {
      // 如果是未归类项目，可能需要切到 Inbox 模式才能看到？
      // 或者我们可以暂时切到 Hierarchy 并允许 selectedDirection 为 null (如果逻辑支持)
      // 目前最稳妥的是切到 Global Inbox 如果没方向
      _mc.setGlobalFilter('inbox');
    }

    // 2. 设置 Project
    _mc.selectProject(p.id);
  }

  void _jumpToTask(Task t) {
    // 直接打开 SessionView
    Get.to(() => SessionView(), arguments: t, binding: SessionBinding());
  }
}
