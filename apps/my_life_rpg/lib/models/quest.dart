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

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'content': content,
    'type': type.toString().split('.').last,
  };

  factory QuestLog.fromJson(Map<String, dynamic> json) => QuestLog(
    id: json['id'],
    createdAt: DateTime.parse(json['createdAt']),
    content: json['content'],
    type: LogType.values.firstWhere(
      (e) => e.toString() == 'LogType.${json['type']}',
      orElse: () => LogType.normal,
    ),
  );
}

class QuestSession {
  final String id;
  final DateTime startTime;
  DateTime? endTime; // null 表示正在进行中
  int durationSeconds; // 冗余存一个时长，方便计算
  final List<QuestLog> logs; // 这个时间片内产生的 Log

  QuestSession({
    String? id,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
    List<QuestLog>? logs,
  }) : id = id ?? const Uuid().v4(),
       logs = logs ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'durationSeconds': durationSeconds,
    'logs': logs.map((e) => e.toJson()).toList(),
  };

  factory QuestSession.fromJson(Map<String, dynamic> json) => QuestSession(
    id: json['id'],
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    durationSeconds: json['durationSeconds'] ?? 0,
    logs:
        (json['logs'] as List?)?.map((e) => QuestLog.fromJson(e)).toList() ??
        [],
  );
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

  // Daemon 专用属性
  final int intervalDays; // 间隔周期 (天)
  final DateTime? lastDoneAt; // 上次完成时间（对于 Routine 是完成时间，对于 Project 是最后一次活跃时间）

  // 核心变化：不再直接存 logs，而是存 sessions
  // 为了兼容旧数据或快速查看，你可以保留一个 get allLogs => sessions.expand((s) => s.logs).toList();
  final List<QuestSession> sessions;

  Quest({
    required this.id,
    required this.title,
    required this.type,
    this.projectId,
    this.projectName,
    this.isCompleted = false,
    this.intervalDays = 0,
    this.lastDoneAt,
    List<QuestSession>? sessions,
  }) : sessions = sessions ?? [];

  // 计算属性：聚合总时长
  int get totalDurationSeconds =>
      sessions.fold(0, (sum, s) => sum + s.durationSeconds);

  // 计算属性：扁平化所有日志 (按时间倒序，方便 UI 展示)
  List<QuestLog> get allLogs {
    final all = sessions.expand((s) => s.logs).toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  // 计算状态 (仅针对 Routine)
  // 返回正数表示逾期天数，负数表示还有几天到期
  int? get dueDays {
    if (type != QuestType.daemon || lastDoneAt == null) return null;
    final nextDue = lastDoneAt!.add(Duration(days: intervalDays));
    final now = DateTime.now();
    return now.difference(nextDue).inDays;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.toString().split('.').last,
    'projectId': projectId,
    'projectName': projectName,
    'isCompleted': isCompleted,
    'intervalDays': intervalDays,
    'lastDoneAt': lastDoneAt?.toIso8601String(),
    'sessions': sessions.map((s) => s.toJson()).toList(),
  };

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
    id: json['id'],
    title: json['title'],
    type: QuestType.values.firstWhere(
      (e) => e.toString() == 'QuestType.${json['type']}',
      orElse: () => QuestType.mission,
    ),
    projectId: json['projectId'],
    projectName: json['projectName'],
    isCompleted: json['isCompleted'] ?? false,
    intervalDays: json['intervalDays'] ?? 0,
    lastDoneAt: json['lastDoneAt'] != null
        ? DateTime.parse(json['lastDoneAt'])
        : null,
    sessions:
        (json['sessions'] as List?)
            ?.map((e) => QuestSession.fromJson(e))
            .toList() ??
        [],
  );
}
