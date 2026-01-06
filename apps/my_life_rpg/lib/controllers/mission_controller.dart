// lib/controllers/mission_controller.dart
import 'package:get/get.dart';
import 'package:my_life_rpg/core/data/specifications.dart';
import 'package:my_life_rpg/core/logic/quest_priority_logic.dart';
import 'package:my_life_rpg/models/direction.dart';
import 'package:my_life_rpg/models/project.dart';
import 'package:my_life_rpg/models/task.dart';
import 'package:my_life_rpg/services/task_service.dart';

enum MissionFilter {
  all, // 显示所有活跃任务
  priority, // 仅显示 Deadline < 24h 或 Overdue
  daemon, // 仅显示循环任务
  project, // 仅显示选中项目的任务
}

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
    // 如果未选中方向，或者处于全局模式，不显示特定项目列表 (或者显示全部)
    // 这里我们定义：选中 Direction 后，中间栏显示归属该 Direction 的 Projects
    if (selectedDirectionId.value == null) return [];

    return _questService.projects
        .where((p) => p.directionId == selectedDirectionId.value)
        .toList();
  }

  // --- 计算属性：右侧显示的任务列表 (Level 3 List) ---
  List<Task> get filteredQuests {
    final allQuests = _questService.tasks;
    Specification<Task> spec = BaseActiveSpec(); // 默认只显示活跃任务

    // 分支 A: 全局模式
    if (viewMode.value == ViewMode.global) {
      switch (globalFilterType.value) {
        case 'urgent':
          spec = spec.and(UrgentSpec());
          break;
        case 'daemon':
          // 仅显示 Routine
          spec = IsRoutineSpec();
          break;
        case 'inbox':
          // 显示无项目的任务 (Standalone)
          spec = spec.and(ProjectSpec(null));
          break;
      }
    }
    // 分支 B: 层级模式
    else {
      if (selectedProjectId.value != null) {
        // 1. 具体项目选中 -> 只看该项目
        spec = spec.and(ProjectSpec(selectedProjectId.value));
      } else if (selectedDirectionId.value != null) {
        // 2. 只选中方向，没选项目 -> 显示该方向下所有项目的聚合任务
        final projectIds = visibleProjects.map((p) => p.id).toSet();
        if (projectIds.isNotEmpty) {
          spec = spec.and(ProjectsInListSpec(projectIds));
        } else {
          // 该方向下没项目 -> 也就没任务 (除非我们允许任务直接挂 Direction，目前暂不支持)
          // 返回一个必假条件，或者是空列表
          return [];
        }
      } else {
        // 3. 啥都没选 (初始状态) -> 也许显示 Dashboard？暂时显示所有 Active
      }
    }

    // 执行过滤
    var list = allQuests.where((q) => spec.isSatisfiedBy(q)).toList();

    // 排序
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
    // 允许 Toggle? 暂时设定为必须选中一个，再次点击不取消
    // 或者再次点击取消选中回到 Direction 视图？我们支持 Toggle
    if (selectedProjectId.value == projectId) {
      selectedProjectId.value = null; // 取消选中，回到 Direction 聚合视图
    } else {
      selectedProjectId.value = projectId;
    }
    viewMode.value = ViewMode.hierarchy;
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
