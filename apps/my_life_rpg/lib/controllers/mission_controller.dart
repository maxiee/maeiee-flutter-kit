// lib/controllers/mission_controller.dart
import 'package:get/get.dart';
import 'package:my_life_rpg/core/data/specifications.dart';
import 'package:my_life_rpg/models/quest.dart';
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
  List<Quest> get filteredQuests {
    final allQuests = _questService.quests;

    // 1. 构建规格 (Build Specification)
    Specification<Quest> spec = BaseActiveSpec(); // 默认基础规则

    switch (activeFilter.value) {
      case MissionFilter.priority:
        // 基础 + 紧急
        spec = spec.and(UrgentSpec());
        break;
      case MissionFilter.daemon:
        // 基础 + 仅Daemon
        spec = spec.and(OnlyDaemonSpec());
        break;
      case MissionFilter.project:
        // 基础 + 特定项目
        if (selectedProjectId.value != null) {
          spec = spec.and(ProjectSpec(selectedProjectId.value));
        }
        break;
      case MissionFilter.all:
      default:
        // 仅基础规则
        break;
    }

    // 2. 执行过滤 (Execute Filter)
    var list = allQuests.where((q) => spec.isSatisfiedBy(q)).toList();

    // 3. 排序 (Sort) - 排序逻辑依然保留在这里，或者也可以抽离为 Comparator
    list.sort(_smartSort);

    return list;
  }

  // 将复杂的排序逻辑抽离为私有方法，保持 get 简洁
  int _smartSort(Quest a, Quest b) {
    // 0. Deadline 已过 (最高优)
    final aDead = a.hoursUntilDeadline < 0;
    final bDead = b.hoursUntilDeadline < 0;
    if (aDead && !bDead) return -1;
    if (!aDead && bDead) return 1;

    // 1. 紧急分数计算
    double getScore(Quest q) {
      if (q.type == QuestType.daemon) {
        final due = q.dueDays ?? 0;
        return due > 0 ? due * 10.0 : 0.0;
      } else {
        final hours = q.hoursUntilDeadline;
        if (hours < 24 && hours > 0) return 24.0 - hours;
        return 0.0;
      }
    }

    final scoreA = getScore(a);
    final scoreB = getScore(b);

    if (scoreA != scoreB) return scoreB.compareTo(scoreA); // 降序

    // 2. 默认按标题
    return a.title.compareTo(b.title);
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
