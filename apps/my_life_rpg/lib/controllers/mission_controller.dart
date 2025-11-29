// lib/controllers/mission_controller.dart
import 'package:get/get.dart';
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
    // 1. 获取所有活跃任务 (基础池)
    // 这里的定义是：Mission未完成，Daemon一直都在(通过dueDays排序)
    // 但为了列表干净，我们只显示 dueDays >= -1 的 Daemon (即昨天、今天、未来到期的)
    var list = _questService.quests.where((q) {
      if (q.type == QuestType.mission) return !q.isCompleted;
      // Daemon 显示规则：逾期 或 今天到期 或 明天到期
      // dueDays: >0 逾期, 0 今天, -1 明天
      return (q.dueDays ?? -999) >= -1;
    }).toList();

    // 2. 应用过滤器
    switch (activeFilter.value) {
      case MissionFilter.priority:
        list = list.where((q) {
          final isUrgent = q.hoursUntilDeadline < 24;
          final isOverdueDaemon = (q.dueDays ?? -99) > 0;
          return isUrgent || isOverdueDaemon;
        }).toList();
        break;

      case MissionFilter.daemon:
        list = list.where((q) => q.type == QuestType.daemon).toList();
        break;

      case MissionFilter.project:
        if (selectedProjectId.value != null) {
          list = list
              .where((q) => q.projectId == selectedProjectId.value)
              .toList();
        }
        break;

      case MissionFilter.all:
      default:
        // do nothing
        break;
    }

    // 3. 排序 (复用之前的智能排序逻辑)
    list.sort((a, b) {
      // 0. 逾期 Deadline 优先
      if (a.hoursUntilDeadline < 0 && b.hoursUntilDeadline >= 0) return -1;
      if (b.hoursUntilDeadline < 0 && a.hoursUntilDeadline >= 0) return 1;

      // 1. 紧急 Daemon 优先 (逾期天数多的)
      int aDue = a.dueDays ?? -99;
      int bDue = b.dueDays ?? -99;
      if (aDue > 0 && bDue <= 0) return -1;
      if (bDue > 0 && aDue <= 0) return 1;
      if (aDue > 0 && bDue > 0) return bDue.compareTo(aDue); // 逾期越久越前

      // 2. 紧急 Mission 优先
      if (a.hoursUntilDeadline < 24 && b.hoursUntilDeadline >= 24) return -1;
      if (b.hoursUntilDeadline < 24 && a.hoursUntilDeadline >= 24) return 1;
      if (a.hoursUntilDeadline < 24 && b.hoursUntilDeadline < 24) {
        return a.hoursUntilDeadline.compareTo(b.hoursUntilDeadline);
      }

      return 0;
    });

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
