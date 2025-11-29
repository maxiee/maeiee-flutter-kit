import '../../models/quest.dart';

class TimeDomain {
  // 常量
  static const int blocksPerDay = 96;
  static const int minutesPerBlock = 15;

  // 纯函数：计算时间块索引
  static int getBlockIndex(DateTime time) {
    return (time.hour * 4) + (time.minute ~/ 15);
  }

  // 纯函数：碰撞检测
  static bool hasOverlap(
    DateTime start,
    DateTime end,
    List<QuestSession> existingSessions, {
    String? excludeSessionId,
  }) {
    for (var s in existingSessions) {
      if (s.id == excludeSessionId) continue;
      DateTime sEnd = s.endTime ?? DateTime.now();
      // 区间重叠公式
      if (start.isBefore(sEnd) && end.isAfter(s.startTime)) return true;
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
