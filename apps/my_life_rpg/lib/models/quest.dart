// lib/models/quest.dart
import 'package:uuid/uuid.dart';

enum QuestType {
  project, // 项目制：如学习、副业，关注总时长和日志流
  routine, // 例行公事：如家务，关注间隔周期
}

class QuestLog {
  final String id;
  final DateTime createdAt;
  final String content; // 你的简短笔记

  QuestLog({String? id, required this.createdAt, required this.content})
    : id = id ?? const Uuid().v4();
}

class Quest {
  final String id;
  final String title;
  final QuestType type;

  // 统计数据
  final int totalDurationSeconds; // 累计投入秒数

  // Routine 专用属性
  final int intervalDays; // 间隔周期 (天)
  final DateTime? lastDoneAt; // 上次完成时间（对于 Routine 是完成时间，对于 Project 是最后一次活跃时间）

  // 日志流 (Timeline)
  final List<QuestLog> logs;

  Quest({
    required this.id,
    required this.title,
    required this.type,
    this.totalDurationSeconds = 0,
    this.intervalDays = 0,
    this.lastDoneAt,
    List<QuestLog>? logs,
  }) : logs = logs ?? [];

  // 计算状态 (仅针对 Routine)
  // 返回正数表示逾期天数，负数表示还有几天到期
  int? get dueDays {
    if (type != QuestType.routine || lastDoneAt == null) return null;
    final nextDue = lastDoneAt!.add(Duration(days: intervalDays));
    final now = DateTime.now();
    return now.difference(nextDue).inDays;
  }
}
