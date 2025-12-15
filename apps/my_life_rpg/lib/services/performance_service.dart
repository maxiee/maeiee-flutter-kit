import 'package:get/get.dart';
import 'package:my_life_rpg/core/utils/logger.dart';
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
    ever(_taskService.tasks, (_) => refreshMetrics());

    // 初始化计算
    refreshMetrics();
  }

  // 公开此方法，允许 TaskService 显式调用
  void refreshMetrics() {
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

      // 2. 时长统计 (核心修复点)
      // 直接遍历 sessions 累加，确保数据源是最新的
      int taskTotal = 0;
      for (var s in task.sessions) {
        // 计算单个 Session 时长
        int duration = s.effectiveSeconds;

        // 如果是进行中，实时补算
        if (s.endTime == null) {
          final currentRunning = now.difference(s.startTime).inSeconds;
          duration = currentRunning - s.pausedSeconds;
        }

        taskTotal += duration;

        // 统计今日 (Daily Output)
        // 判定标准：开始时间是今天 (简化逻辑)
        if (s.startTime.year == now.year &&
            s.startTime.month == now.month &&
            s.startTime.day == now.day) {
          dailySec += duration;
        }
      }
      totalSec += taskTotal;
    }

    // 更新状态
    totalFocusSeconds.value = totalSec;
    dailyFocusSeconds.value = dailySec;
    completedTasksCount.value = completed;
    activeTasksCount.value = active;

    // [Debug] 输出日志，确认计算发生
    LogService.d(
      "Metrics Updated: Total=${totalHoursStr}h, Daily=${dailyHoursStr}h",
      tag: "PerfService",
    );
  }

  // [优化] 累计时长：显示 2 位小数 (例如 15分钟 = 0.25h)
  String get totalHoursStr =>
      (totalFocusSeconds.value / 3600).toStringAsFixed(2);

  // 今日时长
  String get dailyHoursStr =>
      (dailyFocusSeconds.value / 3600).toStringAsFixed(1);

  String get completionRateStr {
    final total = completedTasksCount.value + activeTasksCount.value;
    if (total == 0) return "0%"; // 避免 N/A
    return "${((completedTasksCount.value / total) * 100).toInt()}%";
  }
}
