import '../../models/task.dart';

/// [QuestPriorityLogic]
/// 负责计算任务的优先级分数和排序规则。
/// 这是一个纯逻辑类，封装了"什么任务更重要"的业务知识。
class QuestPriorityLogic {
  /// 标准比较器：用于 List.sort()
  /// 返回值规则遵循 Dart 标准 Comparator:
  /// 负数: a 排在 b 前面
  /// 正数: a 排在 b 后面
  /// 0: 相等
  static int compare(Task a, Task b) {
    // 1. Deadline 已过 (最高优先级，绝对置顶)
    final aOverdue = a.hoursUntilDeadline < 0;
    final bOverdue = b.hoursUntilDeadline < 0;

    // 如果 a 过期但 b 没过期，a 排前面 (-1)
    if (aOverdue && !bOverdue) return -1;
    // 如果 b 过期但 a 没过期，b 排前面 (1)
    if (!aOverdue && bOverdue) return 1;

    // 2. 基于分数的动态排序
    final scoreA = _calculateUrgencyScore(a);
    final scoreB = _calculateUrgencyScore(b);

    // 分数高的排前面 (降序)
    if (scoreA != scoreB) {
      return scoreB.compareTo(scoreA);
    }

    // 3. 兜底策略：按标题字母顺序 (保证列表稳定性)
    return a.title.compareTo(b.title);
  }

  /// 内部辅助：计算紧急程度分数
  /// 分数越高越紧急
  static double _calculateUrgencyScore(Task q) {
    // 策略 A: 守护进程 (Daemon)
    // 根据拖延天数计算，拖得越久分越高
    if (q.type == TaskType.routine) {
      final due = q.dueDays ?? 0;
      // 只有到期(>0)的任务才有高分，每拖一天 +10分
      return due > 0 ? due * 10.0 : 0.0;
    }
    // 策略 B: 普通任务 (Mission)
    // 根据 Deadline 临近程度计算
    else {
      final hours = q.hoursUntilDeadline;
      // 只有 24小时内的任务才开始计分
      // 剩余 1小时 = 23分，剩余 23小时 = 1分
      if (hours < 24 && hours > 0) {
        return 24.0 - hours;
      }
      return 0.0;
    }
  }
}
