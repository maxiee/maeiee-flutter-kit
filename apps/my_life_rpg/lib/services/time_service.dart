import 'dart:async';
import 'package:get/get.dart';
import 'quest_service.dart';

class BlockState {
  final List<String> occupiedQuestIds;
  final List<String> deadlineQuestIds;
  BlockState({
    this.occupiedQuestIds = const [],
    this.deadlineQuestIds = const [],
  });
  bool get isEmpty => occupiedQuestIds.isEmpty && deadlineQuestIds.isEmpty;
}

class TimeService extends GetxService {
  final QuestService _questService = Get.find(); // 依赖注入

  // 状态
  final selectedDate = DateTime.now().obs;
  final timeBlocks = List<BlockState>.generate(96, (_) => BlockState()).obs;

  // 指标
  final dailyXp = 0.obs;
  final timeRemainingStr = ''.obs; // 改名：不再叫 timeToSleep
  final effectiveRatio = 0.0.obs;
  final entropyRatio = 0.0.obs;
  final futureRatio = 1.0.obs;

  // 1. 每日 XP (有效产出)
  final tasksCompletedToday = 0.obs;

  Timer? _heartbeat;

  // 2. 时间感知 (Time Perception)
  final dayStartTime = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    8,
    0,
  ); // 早上 08:00
  final dayEndTime = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day + 1,
    1,
    0,
  ); // 次日 01:00

  @override
  void onInit() {
    super.onInit();
    // 监听：任务列表变化 或 日期选择变化 都要刷新
    ever(_questService.quests, (_) => refreshAll());

    _heartbeat = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _calculateTimeMetrics(),
    );
    _calculateTimeMetrics();
  }

  void refreshAll() {
    _calculateTimeMetrics();
    _refreshTimeBlocks();
  }

  void changeDate(DateTime date) {
    selectedDate.value = date;
    // _refreshTimeBlocks 会被 ever 触发，但 calculateTimeMetrics 需要手动触发一下以防万一
    _refreshTimeBlocks();
  }

  // [修改点]：自然日核心算法
  void _calculateTimeMetrics() {
    final now = DateTime.now();
    final targetDate = selectedDate.value;

    // 判断我们是否在查看“今天”
    final isViewingToday =
        (targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day);

    // 1. 全天固定 1440 分钟 (24小时)
    const totalDayMinutes = 1440;

    // 2. 计算已流逝时间 (Past)
    int elapsedMinutes = 0;
    if (isViewingToday) {
      elapsedMinutes = (now.hour * 60) + now.minute;
    } else if (targetDate.isBefore(now)) {
      elapsedMinutes = 1440; // 过去的日子，全部流逝
    } else {
      elapsedMinutes = 0; // 未来的日子，尚未流逝
    }

    // 3. 计算有效时间 (Effective)
    // 遍历所有任务，找出落在 targetDate 这一天的 Session
    int effectiveSeconds = 0;

    for (var q in _questService.quests) {
      for (var s in q.sessions) {
        // 简单重叠判断：Session 的开始时间必须在 targetDate 当天
        // (注：这里未处理跨越午夜的Session，为保持简单，建议用户在午夜前 Terminate)
        if (s.startTime.year == targetDate.year &&
            s.startTime.month == targetDate.month &&
            s.startTime.day == targetDate.day) {
          effectiveSeconds += s.durationSeconds;
        }
      }
    }
    final effectiveMinutes = effectiveSeconds ~/ 60;

    // 4. 计算熵 (Entropy)
    // 熵 = 流逝的时间 - 有效记录的时间
    int entropyMinutes = elapsedMinutes - effectiveMinutes;
    if (entropyMinutes < 0) entropyMinutes = 0;

    // 5. 更新比率
    effectiveRatio.value = effectiveMinutes / totalDayMinutes;
    entropyRatio.value = entropyMinutes / totalDayMinutes;
    futureRatio.value = (totalDayMinutes - elapsedMinutes) / totalDayMinutes;

    // 6. 倒计时 (距离当天结束)
    if (isViewingToday) {
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final diff = endOfDay.difference(now);
      timeRemainingStr.value =
          "-${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}";
    } else {
      timeRemainingStr.value = "N/A";
    }

    // 7. 计算 XP
    // 统计今天完成的任务 (基于 lastDoneAt 或 完成状态)
    // 这里简单处理：统计所有今天有产出的 Mission 视为活跃
    int activeMissionsCount = 0;
    // 更准确的逻辑：
    // tasksCompletedToday 应该统计 "completedTime" 在今天的。
    // 由于 Quest 模型目前只有 isCompleted 状态，没有 completedAt，暂时用 effectiveMinutes 估算 XP

    // XP 公式：有效分钟数 * 1 + 完成奖励(暂缺)
    dailyXp.value = effectiveMinutes;

    // 简单统计：多少个任务在今天有投入
    tasksCompletedToday.value = _questService.quests.where((q) {
      return q.sessions.any(
        (s) =>
            s.startTime.year == targetDate.year &&
            s.startTime.month == targetDate.month &&
            s.startTime.day == targetDate.day,
      );
    }).length;
  }

  // 刷新时间块数据 (计算密集型，暂放在前端做)
  void _refreshTimeBlocks() {
    // 1. 清空
    for (int i = 0; i < 96; i++) {
      timeBlocks[i] = BlockState(occupiedQuestIds: [], deadlineQuestIds: []);
    }

    final targetDate = selectedDate.value;

    // 2. 填充 Session (实心)
    for (var q in _questService.quests) {
      for (var s in q.sessions) {
        if (s.startTime.year == targetDate.year &&
            s.startTime.month == targetDate.month &&
            s.startTime.day == targetDate.day) {
          // [修改点]：直接计算 0-96 索引，无需偏移
          int startBlock = (s.startTime.hour * 4) + (s.startTime.minute ~/ 15);
          int blocksCount = (s.durationSeconds / 60 / 15).ceil();
          if (blocksCount < 1) blocksCount = 1;

          for (int i = 0; i < blocksCount; i++) {
            int blockIndex = startBlock + i;
            if (blockIndex < 96) {
              final old = timeBlocks[blockIndex];
              timeBlocks[blockIndex] = BlockState(
                occupiedQuestIds: [...old.occupiedQuestIds, q.id],
                deadlineQuestIds: old.deadlineQuestIds,
              );
            }
          }
        }
      }
    }

    // 3. 填充 Deadlines (红框)
    for (var q in _questService.quests) {
      if (q.deadline != null && !q.isAllDayDeadline) {
        if (q.deadline!.year == targetDate.year &&
            q.deadline!.month == targetDate.month &&
            q.deadline!.day == targetDate.day) {
          final blockIndex =
              (q.deadline!.hour * 4) + (q.deadline!.minute ~/ 15);
          if (blockIndex >= 0 && blockIndex < 96) {
            final old = timeBlocks[blockIndex];
            timeBlocks[blockIndex] = BlockState(
              occupiedQuestIds: old.occupiedQuestIds,
              deadlineQuestIds: [...old.deadlineQuestIds, q.id],
            );
          }
        }
      }
    }
    timeBlocks.refresh();
  }
}
