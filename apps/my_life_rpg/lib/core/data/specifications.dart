// lib/core/data/specifications.dart
import '../../models/task.dart';

// --- 基础 Specification 接口保持不变 (T 泛型) ---
abstract class Specification<T> {
  bool isSatisfiedBy(T item);

  // 支持链式调用 (AND)
  Specification<T> and(Specification<T> other) {
    return AndSpecification(this, other);
  }

  Specification<T> or(Specification<T> other) => OrSpecification(this, other);

  Specification<T> not() => NotSpecification(this);
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

class OrSpecification<T> extends Specification<T> {
  final Specification<T> left;
  final Specification<T> right;
  OrSpecification(this.left, this.right);
  @override
  bool isSatisfiedBy(T item) =>
      left.isSatisfiedBy(item) || right.isSatisfiedBy(item);
}

class NotSpecification<T> extends Specification<T> {
  final Specification<T> spec;
  NotSpecification(this.spec);
  @override
  bool isSatisfiedBy(T item) => !spec.isSatisfiedBy(item);
}

// --- 具体业务规则 (Task) ---

// 1. 基础类型
class IsTodoSpec extends Specification<Task> {
  @override
  bool isSatisfiedBy(Task q) => q.type == TaskType.todo;
}

class IsRoutineSpec extends Specification<Task> {
  @override
  bool isSatisfiedBy(Task q) => q.type == TaskType.routine;
}

// 2. 状态
class IsCompletedSpec extends Specification<Task> {
  @override
  bool isSatisfiedBy(Task q) => q.isCompleted;
}

// 3. 时间相关 (新增核心逻辑)

/// 规则：是否需要在特定日期的时间矩阵中显示 Deadline
class DeadlineOnDateSpec extends Specification<Task> {
  final DateTime date;
  DeadlineOnDateSpec(this.date);

  @override
  bool isSatisfiedBy(Task q) {
    if (q.deadline == null) return false;
    // 忽略全天任务 (全天任务显示在顶部，不占用格子)
    if (q.isAllDayDeadline) return false;

    return q.deadline!.year == date.year &&
        q.deadline!.month == date.month &&
        q.deadline!.day == date.day;
  }
}

/// 规则：是否需要在特定日期的时间矩阵中显示 Session 占用
/// 注意：这个规则比较重，因为它需要遍历 Sessions
class HasSessionOnDateSpec extends Specification<Task> {
  final DateTime date;
  HasSessionOnDateSpec(this.date);

  @override
  bool isSatisfiedBy(Task q) {
    for (var s in q.sessions) {
      // 简单判断：Session 的开始时间是当天
      if (s.startTime.year == date.year &&
          s.startTime.month == date.month &&
          s.startTime.day == date.day) {
        return true;
      }
    }
    return false;
  }
}

// --- 组合业务规则 ---

/// 规则：活跃的任务 (未完成的 Mission)
class ActiveTodoSpec extends Specification<Task> {
  @override
  bool isSatisfiedBy(Task q) => q.type == TaskType.todo && !q.isCompleted;
}

/// 规则：活跃的守护进程 (昨天/今天/未来到期的)
class ActiveRoutineSpec extends Specification<Task> {
  @override
  bool isSatisfiedBy(Task q) {
    if (q.type != TaskType.routine) return false;
    final due = q.dueDays ?? -999;
    // 只要不是很久以前(<-1)已经完成且未到期的，都算活跃列表里可见
    // 修正逻辑：列表里通常显示 "Due Today", "Overdue", "Due Tomorrow"
    return due >= -1;
  }
}

/// 规则：基础可见性 (Active Mission OR Active Daemon)
class BaseActiveSpec extends Specification<Task> {
  @override
  bool isSatisfiedBy(Task q) {
    return ActiveTodoSpec().isSatisfiedBy(q) ||
        ActiveRoutineSpec().isSatisfiedBy(q);
  }
}

/// 规则：特定项目
class ProjectSpec extends Specification<Task> {
  final String? projectId;
  // 如果 projectId 为 null，表示筛选 "Standalone" (无项目) 的任务
  ProjectSpec(this.projectId);

  @override
  bool isSatisfiedBy(Task q) => q.projectId == projectId;
}

// 规则：属于项目列表中的任意一个
/// 用于：选中 Direction 时，显示该 Direction 下所有 Project 的任务
class ProjectsInListSpec extends Specification<Task> {
  final Set<String> projectIds;
  ProjectsInListSpec(this.projectIds);

  @override
  bool isSatisfiedBy(Task q) {
    if (q.projectId == null) return false;
    return projectIds.contains(q.projectId);
  }
}

/// 规则：仅 Routine 类型
class OnlyRoutineSpec extends Specification<Task> {
  @override
  bool isSatisfiedBy(Task q) => q.type == TaskType.routine;
}

/// 规则：紧急任务 (Deadline < 24h 或 Overdue Daemon)
class UrgentSpec extends Specification<Task> {
  @override
  bool isSatisfiedBy(Task q) {
    final isUrgentMission = q.hoursUntilDeadline < 24;
    final isOverdueDaemon = (q.dueDays ?? -99) > 0;
    return isUrgentMission || isOverdueDaemon;
  }
}
