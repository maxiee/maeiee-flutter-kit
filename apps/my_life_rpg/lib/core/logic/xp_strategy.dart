/// [XpStrategy]
/// 定义经验值计算规则的接口。
/// 遵循策略模式，允许未来替换不同的算法（如：番茄钟奖励、周末双倍等）。
abstract class XpStrategy {
  /// 计算总经验值
  int calculate(int durationSeconds, bool isCompleted);

  /// 仅计算时长带来的基础经验 (用于实时展示或未完成时的预估)
  int calculateBase(int durationSeconds);
}

/// [StandardXpStrategy]
/// 默认策略：
/// 1. 基础产出：1 分钟 = 1 XP
/// 2. 完成奖励：+50 XP
class StandardXpStrategy implements XpStrategy {
  // 单例模式 (可选，为了方便直接调用，也可以通过 DI 注入)
  static final StandardXpStrategy instance = StandardXpStrategy();

  @override
  int calculateBase(int durationSeconds) {
    // 简单的线性转化：60秒 = 1点
    return (durationSeconds / 60).floor();
  }

  @override
  int calculate(int durationSeconds, bool isCompleted) {
    int base = calculateBase(durationSeconds);
    int bonus = isCompleted ? 50 : 0;
    return base + bonus;
  }
}
