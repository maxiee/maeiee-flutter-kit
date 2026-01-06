// lib/controllers/mission_controller.dart
import 'package:get/get.dart';
import 'package:my_life_rpg/core/data/specifications.dart';
import 'package:my_life_rpg/core/logic/quest_priority_logic.dart';
import 'package:my_life_rpg/models/direction.dart';
import 'package:my_life_rpg/models/project.dart';
import 'package:my_life_rpg/models/task.dart';
import 'package:my_life_rpg/services/task_service.dart';

// 视图模式：决定左侧/中间导航栏的状态
enum ViewMode {
  hierarchy, // 层级模式 (默认)：Direction -> Project
  global, // 全局模式：显示 Urgent, Daemon 等聚合列表
}

class MissionController extends GetxController {
  final TaskService _questService = Get.find();

  // --- 导航状态 (Navigation State) ---
  final viewMode = ViewMode.hierarchy.obs;

  // 层级选择状态
  final selectedDirectionId = RxnString(); // Level 1
  final selectedProjectId = RxnString(); // Level 2

  // 全局过滤器状态 (仅当 viewMode == global 时有效)
  // 复用之前的 Filter 定义，但含义微调
  final globalFilterType = RxString('all'); // 'urgent', 'daemon', 'inbox'

  // --- 计算属性：中间栏显示的项目列表 (Level 2 List) ---
  List<Project> get visibleProjects {
    // Case A: 层级模式 -> 显示选中方向下的项目
    if (viewMode.value == ViewMode.hierarchy &&
        selectedDirectionId.value != null) {
      return _questService.projects
          .where((p) => p.directionId == selectedDirectionId.value)
          .toList();
    }

    // Case B: 全局 INBOX 模式 -> 显示未归类项目 (directionId == null)
    if (viewMode.value == ViewMode.global &&
        globalFilterType.value == 'inbox') {
      return _questService.projects
          .where((p) => p.directionId == null)
          .toList();
    }

    return [];
  }

  // --- 计算属性：右侧显示的任务列表 (Level 3 List) ---
  List<Task> get filteredQuests {
    final allQuests = _questService.tasks;
    Specification<Task> spec = BaseActiveSpec();

    // 优先级最高：如果选中了具体项目，只看该项目 (无论是在层级视图还是 INBOX 视图)
    if (selectedProjectId.value != null) {
      spec = spec.and(ProjectSpec(selectedProjectId.value));
    }
    // 否则：根据视图模式决定
    else if (viewMode.value == ViewMode.global) {
      switch (globalFilterType.value) {
        case 'urgent':
          spec = spec.and(UrgentSpec());
          break;
        case 'daemon':
          spec = IsRoutineSpec();
          break;
        case 'inbox':
          // INBOX 且未选项目 -> 显示无项目的任务 (Standalone)
          spec = spec.and(ProjectSpec(null));
          break;
      }
    } else {
      // 层级模式且未选项目 -> 聚合该方向下所有任务
      if (selectedDirectionId.value != null) {
        final projectIds = visibleProjects.map((p) => p.id).toSet();
        if (projectIds.isNotEmpty) {
          spec = spec.and(ProjectsInListSpec(projectIds));
        } else {
          return [];
        }
      }
    }

    var list = allQuests.where((q) => spec.isSatisfiedBy(q)).toList();
    list.sort(QuestPriorityLogic.compare);
    return list;
  }

  // --- 动作 (Actions) ---

  // 选中方向 (Level 1)
  void selectDirection(String? directionId) {
    if (selectedDirectionId.value == directionId) return; // 重复点击无效

    viewMode.value = ViewMode.hierarchy;
    selectedDirectionId.value = directionId;
    selectedProjectId.value = null; // 重置下一级
  }

  // 选中项目 (Level 2)
  void selectProject(String projectId) {
    if (selectedProjectId.value == projectId) {
      selectedProjectId.value = null;
    } else {
      selectedProjectId.value = projectId;
    }
    // 注意：这里不要强行切 ViewMode，保持当前模式 (可能是 Hierarchy 也可能是 Global Inbox)
  }

  // 切换到全局视图 (Inbox, Urgent, etc.)
  void setGlobalFilter(String filterType) {
    viewMode.value = ViewMode.global;
    globalFilterType.value = filterType;
    // 清除层级选择状态，避免 UI 混淆
    selectedDirectionId.value = null;
    selectedProjectId.value = null;
  }

  // 辅助：获取当前选中的 Direction 对象
  Direction? get activeDirection {
    if (selectedDirectionId.value == null) return null;
    return _questService.directions.firstWhereOrNull(
      (d) => d.id == selectedDirectionId.value,
    );
  }
}
