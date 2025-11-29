// lib/core/data/specifications.dart
import '../../models/quest.dart';

/// 基础规格接口
abstract class Specification<T> {
  bool isSatisfiedBy(T item);

  // 支持链式调用 (AND)
  Specification<T> and(Specification<T> other) {
    return AndSpecification(this, other);
  }
}

/// 组合规格 (AND)
class AndSpecification<T> extends Specification<T> {
  final Specification<T> left;
  final Specification<T> right;
  AndSpecification(this.left, this.right);

  @override
  bool isSatisfiedBy(T item) =>
      left.isSatisfiedBy(item) && right.isSatisfiedBy(item);
}

// --- 具体业务规则 ---

/// 规则：活跃的任务 (未完成的 Mission)
class ActiveMissionSpec extends Specification<Quest> {
  @override
  bool isSatisfiedBy(Quest q) => q.type == QuestType.mission && !q.isCompleted;
}

/// 规则：活跃的守护进程 (昨天/今天/未来到期的)
class ActiveDaemonSpec extends Specification<Quest> {
  @override
  bool isSatisfiedBy(Quest q) {
    if (q.type != QuestType.daemon) return false;
    final due = q.dueDays ?? -999;
    // 只要不是很久以前(<-1)已经完成且未到期的，都算活跃列表里可见
    // 修正逻辑：列表里通常显示 "Due Today", "Overdue", "Due Tomorrow"
    return due >= -1;
  }
}

/// 规则：基础可见性 (Active Mission OR Active Daemon)
class BaseActiveSpec extends Specification<Quest> {
  @override
  bool isSatisfiedBy(Quest q) {
    return ActiveMissionSpec().isSatisfiedBy(q) ||
        ActiveDaemonSpec().isSatisfiedBy(q);
  }
}

/// 规则：特定项目
class ProjectSpec extends Specification<Quest> {
  final String? projectId;
  ProjectSpec(this.projectId);

  @override
  bool isSatisfiedBy(Quest q) => q.projectId == projectId;
}

/// 规则：仅 Daemon 类型
class OnlyDaemonSpec extends Specification<Quest> {
  @override
  bool isSatisfiedBy(Quest q) => q.type == QuestType.daemon;
}

/// 规则：紧急任务 (Deadline < 24h 或 Overdue Daemon)
class UrgentSpec extends Specification<Quest> {
  @override
  bool isSatisfiedBy(Quest q) {
    final isUrgentMission = q.hoursUntilDeadline < 24;
    final isOverdueDaemon = (q.dueDays ?? -99) > 0;
    return isUrgentMission || isOverdueDaemon;
  }
}
