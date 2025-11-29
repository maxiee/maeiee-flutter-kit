abstract class XpStrategy {
  int calculate(int durationSeconds, bool isCompleted);
}

class StandardXpStrategy implements XpStrategy {
  @override
  int calculate(int durationSeconds, bool isCompleted) {
    // 基础：1分钟 = 1XP
    int base = (durationSeconds / 60).floor();
    // 奖励：完成任务额外 +50
    int bonus = isCompleted ? 50 : 0;
    return base + bonus;
  }
}

// 未来可以有 ProXpStrategy (加倍), WeekendXpStrategy 等
