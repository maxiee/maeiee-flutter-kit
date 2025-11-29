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
  final timeToSleep = ''.obs;
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
    // 监听任务变化，自动刷新矩阵 (Reactive Programming!)
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
    _refreshTimeBlocks();
  }

  // ... 搬运 _calculateTimeMetrics 逻辑 (注意 quests 来源变成 _questService.quests) ...
  // ... 搬运 _refreshTimeBlocks 逻辑 ...

  // 辅助方法
  // 核心算法：计算当天的时间分布
  void _calculateTimeMetrics() {
    final now = DateTime.now();

    // 1. 计算总跨度 (比如 08:00 - 01:00 = 17小时)
    final totalDaySpan = dayEndTime.difference(dayStartTime).inMinutes;
    if (totalDaySpan <= 0) return;

    // 2. 计算已流逝时间 (Past)
    final elapsedMinutes = now
        .difference(dayStartTime)
        .inMinutes
        .clamp(0, totalDaySpan);

    // 3. 计算有效时间 (Effective) - 遍历今天所有 Quest 的 totalDuration
    // *注意：为了 MVP，这里我们暂时假设 totalDurationSeconds 都是今天产生的。
    // *实际项目中，QuestLog 应该包含 duration，这里累加今天的 Log duration。
    int effectiveMinutes = 0;
    for (var q in _questService.quests) {
      for (var s in q.sessions) {
        // 判断 session 是否在今天 (简单判断 startTime)
        if (s.startTime.year == now.year &&
            s.startTime.month == now.month &&
            s.startTime.day == now.day) {
          effectiveMinutes += (s.durationSeconds / 60).round();
        }
      }
    }

    // 4. 计算熵 (Entropy / Wasted)
    // 熵 = 流逝时间 - 有效时间
    int entropyMinutes = elapsedMinutes - effectiveMinutes;
    if (entropyMinutes < 0) entropyMinutes = 0; // 避免负数

    // 5. 更新比率 (用于 UI 进度条)
    effectiveRatio.value = effectiveMinutes / totalDaySpan;
    entropyRatio.value = entropyMinutes / totalDaySpan;
    futureRatio.value = (totalDaySpan - elapsedMinutes) / totalDaySpan;

    // 6. 倒计时
    final diff = dayEndTime.difference(now);
    if (diff.isNegative) {
      timeToSleep.value = "OVERTIME";
    } else {
      timeToSleep.value =
          "-${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}";
    }

    // 7. 计算 XP
    // 简单公式：1分钟有效时间 = 1 XP，完成一个任务 = 50 XP
    int completedCount = _questService.quests
        .where((q) => q.isCompleted)
        .length; // 实际应判断完成时间是否是今天
    tasksCompletedToday.value = completedCount;
    dailyXp.value = effectiveMinutes + (completedCount * 50);
  }

  // 刷新时间块数据 (计算密集型，暂放在前端做)
  void _refreshTimeBlocks() {
    // 1. 重置所有格子 (必须先清空)
    for (int i = 0; i < 96; i++) {
      timeBlocks[i] = BlockState(occupiedQuestIds: [], deadlineQuestIds: []);
    }

    final targetDate = selectedDate.value;

    // 2. 第一遍遍历：填充 Sessions (实心填充)
    for (var q in _questService.quests) {
      for (var s in q.sessions) {
        if (s.startTime.year == targetDate.year &&
            s.startTime.month == targetDate.month &&
            s.startTime.day == targetDate.day) {
          int startBlock = (s.startTime.hour * 4) + (s.startTime.minute ~/ 15);
          int blocksCount = (s.durationSeconds / 60 / 15).ceil();
          if (blocksCount < 1) blocksCount = 1;

          for (int i = 0; i < blocksCount; i++) {
            int blockIndex = startBlock + i;
            if (blockIndex < 96) {
              // 取出旧状态，追加 occupied
              final old = timeBlocks[blockIndex];
              timeBlocks[blockIndex] = BlockState(
                occupiedQuestIds: [...old.occupiedQuestIds, q.id], // 追加
                deadlineQuestIds: old.deadlineQuestIds, // 保持
              );
            }
          }
        }
      }
    }

    // 3. 第二遍遍历：填充 Deadlines (红框警告)
    for (var q in _questService.quests) {
      if (q.deadline != null && !q.isAllDayDeadline) {
        // 只有精确时间的才进格子
        if (q.deadline!.year == targetDate.year &&
            q.deadline!.month == targetDate.month &&
            q.deadline!.day == targetDate.day) {
          final blockIndex =
              (q.deadline!.hour * 4) + (q.deadline!.minute ~/ 15);

          if (blockIndex >= 0 && blockIndex < 96) {
            // 取出旧状态，追加 deadline
            final old = timeBlocks[blockIndex];
            timeBlocks[blockIndex] = BlockState(
              occupiedQuestIds: old.occupiedQuestIds, // 保持
              deadlineQuestIds: [...old.deadlineQuestIds, q.id], // 追加
            );
          }
        }
      }
    }

    // 4. 通知 UI 更新
    timeBlocks.refresh();
  }
}
