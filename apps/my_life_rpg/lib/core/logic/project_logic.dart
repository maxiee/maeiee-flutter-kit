import '../../models/project.dart';
import '../../models/task.dart';

/// [ProjectLogic]
/// 专门负责项目相关的业务计算。
class ProjectLogic {
  /// 计算项目进度 (0.0 - 1.0)
  /// [project]: 目标项目
  /// [relatedQuests]: 该项目下的所有任务
  static double calculateProgress(Project project, List<Task> relatedQuests) {
    // 策略 A: 如果设定了目标小时数，按时间投入计算
    if (project.targetHours > 0) {
      // 累加所有关联任务的总时长 (秒)
      int totalSeconds = relatedQuests.fold(
        0,
        (sum, q) => sum + q.totalDurationSeconds,
      );

      // 计算：当前投入小时 / 目标小时
      // 使用 clamp 限制在 0.0 - 1.0 之间
      return (totalSeconds / 3600 / project.targetHours).clamp(0.0, 1.0);
    }
    // 策略 B: 默认按任务完成数计算 (仅计算 Mission 类型)
    else {
      final missions = relatedQuests
          .where((q) => q.type == TaskType.todo)
          .toList();

      if (missions.isEmpty) return 0.0;

      final completedCount = missions.where((q) => q.isCompleted).length;
      return completedCount / missions.length;
    }
  }
}
