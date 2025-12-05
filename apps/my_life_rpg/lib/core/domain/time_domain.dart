import 'package:get/get.dart';
import 'package:my_life_rpg/core/constants.dart';
import 'package:my_life_rpg/core/data/specifications.dart';
import 'package:my_life_rpg/models/block_state.dart';

import '../../models/task.dart';

/// [TimeDomain]
/// 包含所有与时间计算相关的纯算法。
/// 此类不依赖 Flutter UI 库，也不依赖 GetX 状态，仅处理数据逻辑。
class TimeDomain {
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
    List<Task> quests,
  ) {
    // 0. 初始化空网格
    final List<BlockState> blocks = List.generate(
      Constants.blocksPerDay,
      (_) => BlockState.empty(),
    );

    // 1. 预筛选：只处理跟当天有关的任务 (性能优化)
    // 使用 OR 组合规则：(有当天 Session) OR (有当天 Deadline)
    final relevantSpec = HasSessionOnDateSpec(
      targetDate,
    ).or(DeadlineOnDateSpec(targetDate));

    final dailyQuests = quests
        .where((q) => relevantSpec.isSatisfiedBy(q))
        .toList();

    // 2. 填充 Sessions (实心块)
    // 只处理那些确实有 Session 在今天的任务
    for (var q in dailyQuests) {
      for (var s in q.sessions) {
        // 二次确认 Session 是否在当天 (Spec 只是 Quest 级别的筛选)
        if (s.startTime.year == targetDate.year &&
            s.startTime.month == targetDate.month &&
            s.startTime.day == targetDate.day) {
          int startBlock = getBlockIndex(s.startTime);
          int blocksCount = (s.durationSeconds / 60 / Constants.minutesPerBlock)
              .ceil();
          if (blocksCount < 1) blocksCount = 1;

          for (int i = 0; i < blocksCount; i++) {
            int blockIndex = startBlock + i;
            if (blockIndex < Constants.blocksPerDay) {
              final old = blocks[blockIndex];
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

    // 3. 填充 Deadlines (红框)
    // 使用 DeadlineOnDateSpec 过滤
    final deadlineSpec = DeadlineOnDateSpec(targetDate);
    final deadlineQuests = dailyQuests.where(
      (q) => deadlineSpec.isSatisfiedBy(q),
    );

    for (var q in deadlineQuests) {
      // 这里的 q 已经保证是当天 Deadline 且非全天
      // 直接获取时间即可，无需再次 if 判断
      final blockIndex = getBlockIndex(q.deadline!);

      if (blockIndex >= 0 && blockIndex < Constants.blocksPerDay) {
        final old = blocks[blockIndex];
        blocks[blockIndex] = BlockState(
          occupiedQuestIds: old.occupiedQuestIds,
          occupiedSessionIds: old.occupiedSessionIds,
          deadlineQuestIds: [...old.deadlineQuestIds, q.id],
        );
      }
    }

    // [新增] 4. 后处理：计算 Label 和 Span (按小时行处理)
    // 遍历每一行 (24行)
    for (int h = 0; h < 24; h++) {
      int rowStart = h * 4;

      // 遍历该行的 4 个 quarter
      for (int i = 0; i < 4; i++) {
        int currentIndex = rowStart + i;
        BlockState current = blocks[currentIndex];

        // 如果该格为空，跳过
        if (current.occupiedSessionIds.isEmpty) continue;

        String currentSessionId = current.occupiedSessionIds.last;
        String currentQuestId = current.occupiedQuestIds.last;

        // 检查前一个格子 (同一行内) 是否是同一个 Session
        bool isContinuation = false;
        if (i > 0) {
          BlockState prev = blocks[currentIndex - 1];
          if (prev.occupiedSessionIds.isNotEmpty &&
              prev.occupiedSessionIds.last == currentSessionId) {
            isContinuation = true;
          }
        }

        // 如果是延续块，它不需要 Label
        if (isContinuation) continue;

        // 如果是新块 (Header)，计算 Span
        int span = 1;
        for (int j = i + 1; j < 4; j++) {
          int nextIndex = rowStart + j;
          BlockState next = blocks[nextIndex];
          if (next.occupiedSessionIds.isNotEmpty &&
              next.occupiedSessionIds.last == currentSessionId) {
            span++;
          } else {
            break;
          }
        }

        // 查找 Quest Title (为了不可变，这里需要遍历 quests 列表，虽然是 O(N)，但在 Domain 层计算一次比 View 层每帧算好)
        // 优化：dailyQuests 比较小
        String title = "Unknown";
        final q = dailyQuests.firstWhereOrNull(
          (task) => task.id == currentQuestId,
        );
        if (q != null) title = q.title;

        // 更新当前 Block 的状态
        blocks[currentIndex] = current.copyWith(label: title, span: span);
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
    List<FocusSession> existingSessions, {
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
    List<FocusSession> sessions,
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
