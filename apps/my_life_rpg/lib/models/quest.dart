// lib/models/quest.dart
import 'package:uuid/uuid.dart';

enum QuestType {
  mission, // 普通任务 (一次性)
  daemon, // 守护进程 (循环)
}

enum LogType {
  normal, // 普通文本
  milestone, // 里程碑 (金色)
  bug, // 坑/Bug (红色)
  idea, // 想法 (青色)
  rest, // 休息 (绿色)
}

class QuestLog {
  final String id;
  final DateTime createdAt;
  final String content; // 你的简短笔记
  final LogType type; // 新增属性

  QuestLog({
    String? id,
    required this.createdAt,
    required this.content,
    this.type = LogType.normal, // 默认为普通
  }) : id = id ?? const Uuid().v4();
}

class Quest {
  final String id;
  final String title;
  final QuestType type;

  // 关联 Project
  final String? projectId; // 比如关联 "Flutter学习" 项目
  final String? projectName; // 冗余存一个名字方便显示

  // 状态
  bool isCompleted; // 是否已完成 (打钩)

  // 统计数据
  int totalDurationSeconds; // 累计投入秒数
  final List<QuestLog> logs; // 日志流 (Timeline)

  // Daemon 专用属性
  final int intervalDays; // 间隔周期 (天)
  final DateTime? lastDoneAt; // 上次完成时间（对于 Routine 是完成时间，对于 Project 是最后一次活跃时间）

  Quest({
    required this.id,
    required this.title,
    required this.type,
    this.projectId,
    this.projectName,
    this.isCompleted = false,
    this.totalDurationSeconds = 0,
    this.intervalDays = 0,
    this.lastDoneAt,
    List<QuestLog>? logs,
  }) : logs = logs ?? [];

  // 计算状态 (仅针对 Routine)
  // 返回正数表示逾期天数，负数表示还有几天到期
  int? get dueDays {
    if (type != QuestType.daemon || lastDoneAt == null) return null;
    final nextDue = lastDoneAt!.add(Duration(days: intervalDays));
    final now = DateTime.now();
    return now.difference(nextDue).inDays;
  }
}
