import 'package:my_life_rpg/models/block_state.dart';

import '../../models/quest.dart';

/// [TimeDomain]
/// 包含所有与时间计算相关的纯算法。
/// 此类不依赖 Flutter UI 库，也不依赖 GetX 状态，仅处理数据逻辑。
class TimeDomain {
  // 常量
  static const int blocksPerDay = 96;
  static const int minutesPerBlock = 15;

  /// 纯函数：计算时间块索引 (0 - 95)
  static int getBlockIndex(DateTime time) {
    return (time.hour * 4) + (time.minute ~/ 15);
  }

  /// 纯函数：生成指定日期的全天时间块状态
  ///
  /// [targetDate]: 需要生成矩阵的日期
  /// [quests]: 所有任务列表 (由此函数内部进行筛选)
  /// Returns: 固定长度为 96 的 BlockState 列表
  static List<BlockState> generateDailyBlocks(
    DateTime targetDate,
    List<Quest> quests,
  ) {
    // 1. 初始化空网格
    final List<BlockState> blocks = List.generate(
      blocksPerDay,
      (_) => BlockState.empty(),
    );

    // 2. 填充 Sessions (实心块逻辑)
    for (var q in quests) {
      for (var s in q.sessions) {
        // 筛选：只处理落在目标日期的 Session
        // 注意：这里简化了跨天逻辑，假设 Session 不跨天或只显示当天部分
        if (s.startTime.year == targetDate.year &&
            s.startTime.month == targetDate.month &&
            s.startTime.day == targetDate.day) {
          // 计算起始索引
          int startBlock = getBlockIndex(s.startTime);

          // 计算占用块数 (向上取整)
          int blocksCount = (s.durationSeconds / 60 / minutesPerBlock).ceil();
          if (blocksCount < 1) blocksCount = 1;

          // 填充网格
          for (int i = 0; i < blocksCount; i++) {
            int blockIndex = startBlock + i;

            // 边界保护：防止索引越界 (比如 23:50 开始的任务)
            if (blockIndex < blocksPerDay) {
              final old = blocks[blockIndex];

              // CopyWith 逻辑 (虽然没有写 copyWith 方法，直接创建新对象)
              blocks[blockIndex] = BlockState(
                occupiedQuestIds: [...old.occupiedQuestIds, q.id],
                occupiedSessionIds: [...old.occupiedSessionIds, s.id],
                deadlineQuestIds: old.deadlineQuestIds,
              );
            }
          }
        }
      }
    }

    // 3. 填充 Deadlines (红框逻辑)
    for (var q in quests) {
      // 筛选：有具体时间的 Deadline 且在当天
      if (q.deadline != null && !q.isAllDayDeadline) {
        if (q.deadline!.year == targetDate.year &&
            q.deadline!.month == targetDate.month &&
            q.deadline!.day == targetDate.day) {
          final blockIndex = getBlockIndex(q.deadline!);

          if (blockIndex >= 0 && blockIndex < blocksPerDay) {
            final old = blocks[blockIndex];
            blocks[blockIndex] = BlockState(
              occupiedQuestIds: old.occupiedQuestIds,
              occupiedSessionIds: old.occupiedSessionIds,
              deadlineQuestIds: [...old.deadlineQuestIds, q.id],
            );
          }
        }
      }
    }

    return blocks;
  }

  /// [追加/确认] 纯函数：碰撞检测
  /// 判断 [start, end] 区间是否与现有 Sessions 存在重叠
  ///
  /// [start], [end]: 待检测的时间段
  /// [existingSessions]: 现有的所有 Session 列表 (通常来自所有 Quests)
  /// [excludeSessionId]: 排除自身的 ID (用于编辑场景，暂可选)
  static bool hasOverlap(
    DateTime start,
    DateTime end,
    List<QuestSession> existingSessions, {
    String? excludeSessionId,
  }) {
    for (var s in existingSessions) {
      if (s.id == excludeSessionId) continue;

      // 获取 Session 的结束时间 (如果是进行中，视为冲突风险，暂定为 Now)
      DateTime sEnd = s.endTime ?? DateTime.now();

      // 经典的区间重叠公式: (StartA < EndB) and (EndA > StartB)
      // 使用 isBefore/isAfter 处理
      if (start.isBefore(sEnd) && end.isAfter(s.startTime)) {
        return true; // 发生碰撞
      }
    }
    return false;
  }

  // 纯函数：计算自然日内的有效时长 (解决跨天问题的核心算法)
  static int calculateEffectiveSeconds(
    List<QuestSession> sessions,
    DateTime targetDate,
  ) {
    int total = 0;
    final dayStart = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));

    for (var s in sessions) {
      // 简单的包含判断 (根据之前的简化逻辑)
      // 如果要硬核，这里应该做精确的“区间截断”计算
      // 比如 session 跨越了午夜，只计算落在 targetDate 内的部分

      DateTime sEnd = s.endTime ?? DateTime.now();

      // 计算交集
      final overlapStart = s.startTime.isAfter(dayStart)
          ? s.startTime
          : dayStart;
      final overlapEnd = sEnd.isBefore(dayEnd) ? sEnd : dayEnd;

      if (overlapStart.isBefore(overlapEnd)) {
        total += overlapEnd.difference(overlapStart).inSeconds;
      }
    }
    return total;
  }
}
