import 'package:get/get.dart';
import 'package:my_life_rpg/models/task.dart';
import 'package:my_life_rpg/services/task_service.dart';

/// 负责统计用户的生产力指标。
/// 核心指标：
/// 1. Total Focus Hours (总专注时长)
/// 2. Daily Output (今日产出时长)
/// 3. Completion Rate (任务完成率)
class PerformanceService extends GetxService {
  final TaskService _taskService = Get.find();

  // --- Metrics (可观测指标) ---
  final totalFocusSeconds = 0.obs;
  final dailyFocusSeconds = 0.obs;
  final completedTasksCount = 0.obs;
  final activeTasksCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // 监听任务数据变化，重新计算统计数据
    ever(_taskService.tasks, (_) => _calculateMetrics());
  }

  void _calculateMetrics() {
    int totalSec = 0;
    int dailySec = 0;
    int completed = 0;
    int active = 0;

    final now = DateTime.now();

    for (var task in _taskService.tasks) {
      // 1. 任务计数
      if (task.type == TaskType.todo) {
        if (task.isCompleted) {
          completed++;
        } else {
          active++;
        }
      }

      // 2. 时长统计 (基于物理时间)
      // 累加历史 Session
      totalSec += task.totalDurationSeconds;

      // 累加今日 Session
      for (var s in task.sessions) {
        // 判断是否属于"今天" (简单处理，不含跨天分割，那是 TimeDomain 的事)
        if (s.startTime.year == now.year &&
            s.startTime.month == now.month &&
            s.startTime.day == now.day) {
          // 如果 Session 正在进行中，实时计算
          if (s.endTime == null) {
            final currentDuration = now.difference(s.startTime).inSeconds;
            dailySec += (currentDuration - s.pausedSeconds);
          } else {
            dailySec += s.effectiveSeconds;
          }
        }
      }
    }

    // 更新状态
    totalFocusSeconds.value = totalSec;
    dailyFocusSeconds.value = dailySec;
    completedTasksCount.value = completed;
    activeTasksCount.value = active;
  }

  // 计算属性：总小时数 (保留1位小数)
  String get totalHoursStr =>
      (totalFocusSeconds.value / 3600).toStringAsFixed(1);

  // 计算属性：今日小时数
  String get dailyHoursStr =>
      (dailyFocusSeconds.value / 3600).toStringAsFixed(1);

  // 计算属性：完成率
  String get completionRateStr {
    final total = completedTasksCount.value + activeTasksCount.value;
    if (total == 0) return "N/A";
    return "${((completedTasksCount.value / total) * 100).toInt()}%";
  }
}
