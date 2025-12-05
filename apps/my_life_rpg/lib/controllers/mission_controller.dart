// lib/controllers/mission_controller.dart
import 'package:get/get.dart';
import 'package:my_life_rpg/core/data/specifications.dart';
import 'package:my_life_rpg/core/logic/quest_priority_logic.dart';
import 'package:my_life_rpg/models/task.dart';
import 'package:my_life_rpg/services/quest_service.dart';

enum MissionFilter {
  all, // 显示所有活跃任务
  priority, // 仅显示 Deadline < 24h 或 Overdue
  daemon, // 仅显示循环任务
  project, // 仅显示选中项目的任务
}

class MissionController extends GetxController {
  final QuestService _questService = Get.find();

  // 筛选状态
  final activeFilter = MissionFilter.all.obs;
  final selectedProjectId = RxnString(); // 当 filter == project 时有效

  // 计算属性：根据筛选器返回过滤后的任务列表
  List<Task> get filteredQuests {
    final allQuests = _questService.quests;

    // 1. 构建规格 (Build Specification)
    Specification<Task> spec;

    // 1. 基础可见性规则 (Active Mission OR Active Daemon)
    // 这是所有列表的基础
    final baseSpec = ActiveTodoSpec().or(ActiveRoutineSpec());

    switch (activeFilter.value) {
      case MissionFilter.priority:
        // 基础 AND 紧急
        spec = baseSpec.and(UrgentSpec());
        break;

      case MissionFilter.daemon:
        // 仅 Daemon (忽略 ActiveMissionSpec，直接看所有 Daemon)
        // 这里可能有业务歧义：是看“活跃的Daemon”还是“所有的Daemon”？
        // 假设是看所有已配置的 Daemon 列表
        spec = IsRoutineSpec();
        break;

      case MissionFilter.project:
        if (selectedProjectId.value != null) {
          // 项目下的所有活跃任务 (包括 Mission 和 Daemon)
          spec = baseSpec.and(ProjectSpec(selectedProjectId.value));
        } else {
          spec = baseSpec;
        }
        break;

      case MissionFilter.all:
        spec = baseSpec;
        break;
    }

    // 2. 执行过滤 (Execute Filter)
    var list = allQuests.where((q) => spec.isSatisfiedBy(q)).toList();

    // 3. 排序 (Sort) - 排序逻辑依然保留在这里，或者也可以抽离为 Comparator
    list.sort(QuestPriorityLogic.compare);

    return list;
  }

  // 动作：切换过滤器
  void setFilter(MissionFilter filter) {
    activeFilter.value = filter;
    // 如果切到非 Project，清空选中项目
    if (filter != MissionFilter.project) {
      selectedProjectId.value = null;
    }
  }

  // 动作：选中项目 (由 CampaignBar 调用)
  void selectProject(String projectId) {
    // 如果已经选中它，且当前就是 project 模式 -> 取消选中 (Toggle)
    if (activeFilter.value == MissionFilter.project &&
        selectedProjectId.value == projectId) {
      setFilter(MissionFilter.all);
    } else {
      selectedProjectId.value = projectId;
      activeFilter.value = MissionFilter.project;
    }
  }
}
