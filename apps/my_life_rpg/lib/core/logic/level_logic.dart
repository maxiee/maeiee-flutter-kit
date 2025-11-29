// lib/core/logic/level_logic.dart

import 'dart:math';

class LevelInfo {
  final int level;
  final String title;
  final int currentLevelXp; // 当前等级已获得的 XP (用于进度条分子)
  final int nextLevelXp; // 升级所需总 XP (用于进度条分母)
  final double progress; // 0.0 - 1.0

  LevelInfo({
    required this.level,
    required this.title,
    required this.currentLevelXp,
    required this.nextLevelXp,
    required this.progress,
  });
}

class LevelLogic {
  // 基础系数：数值越大，升级越慢
  // 设为 50，则 Lv2 需要 200 XP (~3.3小时), Lv10 需要 5000 XP (~83小时)
  static const int _baseConstant = 50;

  static LevelInfo calculate(int totalXp) {
    // 1. 计算当前等级
    // XP = level^2 * 50  =>  level = sqrt(XP / 50)
    int level = 1;
    if (totalXp > 0) {
      level = sqrt(totalXp / _baseConstant).floor();
      if (level < 1) level = 1;
    }

    // 2. 计算当前等级的起止区间
    // Lv.N 的总 XP 门槛 = N^2 * 50
    int startXp = (level * level) * _baseConstant;
    int endXp = ((level + 1) * (level + 1)) * _baseConstant;

    // 3. 计算进度
    int range = endXp - startXp;
    int current = totalXp - startXp;
    // 边界保护 (防止 level=1 startXp=0 的情况出现负数，虽然理论上不会)
    if (current < 0) current = 0;

    double progress = range == 0 ? 0.0 : current / range;

    return LevelInfo(
      level: level,
      title: _getTitle(level),
      currentLevelXp: current,
      nextLevelXp: range, // 这里指当前等级升级所需的增量 XP
      progress: progress,
    );
  }

  // 赛博朋克风格称号表
  static String _getTitle(int level) {
    if (level >= 60) return "CYBER DEITY"; // 赛博神
    if (level >= 50) return "SYSTEM ARCHITECT"; // 架构师
    if (level >= 40) return "NETRUNNER LEGEND"; // 传奇黑客
    if (level >= 30) return "SENIOR OPERATOR"; // 高级操作员
    if (level >= 20) return "CONSOLE COWBOY"; // 控制台牛仔
    if (level >= 10) return "SCRIPT KIDDIE"; // 脚本小子
    return "NOVICE"; // 新手
  }
}
