import 'package:my_life_rpg/models/serializable.dart';
import 'package:uuid/uuid.dart';

enum TaskType {
  todo, // 单次待办
  routine, // 循环习惯
}

extension TaskTypeExt on TaskType {
  String get name => toString().split('.').last;

  static TaskType fromJson(String json) => TaskType.values.firstWhere(
    (e) => e.name == json,
    orElse: () => TaskType.todo,
  );
}

enum LogType {
  normal, // 笔记
  milestone, // 节点
  bug, // 问题
  idea, // 灵感
  rest, // 休息
}

extension LogTypeExt on LogType {
  String toJson() => toString().split('.').last;

  static LogType fromJson(String json) {
    return LogType.values.firstWhere(
      (e) => e.toJson() == json,
      orElse: () => LogType.normal,
    );
  }
}

class TaskLog {
  final String id;
  final DateTime createdAt;
  final String content; // 你的简短笔记
  final LogType type; // 新增属性

  TaskLog({
    String? id,
    required this.createdAt,
    required this.content,
    this.type = LogType.normal, // 默认为普通
  }) : id = id ?? const Uuid().v4();

  // Dart 3 风格写法
  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'content': content,
    'type': type.name, // 使用 .name
  };

  factory TaskLog.fromJson(Map<String, dynamic> json) => TaskLog(
    id: json['id'],
    createdAt: DateTime.parse(json['createdAt']),
    content: json['content'],
    type: LogType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => LogType.normal,
    ),
  );
}

class FocusSession {
  final String id;
  final DateTime startTime;
  DateTime? endTime; // null 表示正在进行中
  int durationSeconds; // 物理时长
  int pausedSeconds; // 暂停时长

  // 不再直接存 Log，Log 属于 Task 还是 Session？通常 Log 发生在 Session 期间
  final List<TaskLog> logs;

  FocusSession({
    String? id,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
    this.pausedSeconds = 0,
    List<TaskLog>? logs,
  }) : id = id ?? const Uuid().v4(),
       logs = logs ?? [];

  // 计算属性：有效专注时长 (总时长 - 暂停时长)
  // 如果正在进行中，需要动态计算
  int get effectiveSeconds => durationSeconds - pausedSeconds;

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'durationSeconds': durationSeconds,
    'pausedSeconds': pausedSeconds,
    'logs': logs.map((e) => e.toJson()).toList(),
  };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
    id: json['id'],
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    durationSeconds: json['durationSeconds'] ?? 0,
    pausedSeconds: json['pausedSeconds'] ?? 0,
    logs:
        (json['logs'] as List?)?.map((e) => TaskLog.fromJson(e)).toList() ?? [],
  );
}

class Task implements Serializable {
  @override
  final String id;
  final String title;
  final TaskType type;

  // 关联 Project
  final String? projectId; // 比如关联 "Flutter学习" 项目
  final String? projectName; // 冗余存一个名字方便显示

  // 状态
  bool isCompleted; // 是否已完成 (打钩)

  // Routine 专用
  final int intervalDays; // 间隔周期 (天)
  final DateTime? lastDoneAt; // 上次完成时间（对于 Routine 是完成时间，对于 Project 是最后一次活跃时间）

  final DateTime? deadline;
  final bool isAllDayDeadline; // true=当天截止(显示在顶部), false=精确时间(显示在格子里)

  // 核心变化：不再直接存 logs，而是存 sessions
  // 为了兼容旧数据或快速查看，你可以保留一个 get allLogs => sessions.expand((s) => s.logs).toList();
  final List<FocusSession> sessions;

  Task({
    required this.id,
    required this.title,
    required this.type,
    this.projectId,
    this.projectName,
    this.isCompleted = false,
    this.intervalDays = 0,
    this.lastDoneAt,
    this.deadline,
    this.isAllDayDeadline = true,
    List<FocusSession>? sessions,
  }) : sessions = sessions ?? [];

  bool get isUrgent => hoursUntilDeadline < 24;
  bool get isOverdue => hoursUntilDeadline < 0;

  bool get isDaemonOverdue => type == TaskType.routine && (dueDays ?? -99) > 0;

  // 计算属性：聚合总时长
  int get totalDurationSeconds =>
      sessions.fold(0, (sum, s) => sum + s.durationSeconds);

  // 计算属性：扁平化所有日志 (按时间倒序，方便 UI 展示)
  List<TaskLog> get allLogs {
    final all = sessions.expand((s) => s.logs).toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  // 计算属性：紧急程度 (用于排序)
  // 返回：剩余小时数。负数表示已逾期。
  double get hoursUntilDeadline {
    if (deadline == null) return double.infinity;
    return deadline!.difference(DateTime.now()).inMinutes / 60.0;
  }

  // [修改点]：基于自然日期的到期计算
  // 返回值：
  // 0 = 今天到期 (Due Today)
  // >0 = 已逾期 X 天 (Overdue)
  // <0 = 还有 X 天 (Future)
  int? get dueDays {
    if (type != TaskType.routine || lastDoneAt == null) return null;

    // 剥离时间，只保留日期部分 (00:00:00)
    final lastDate = DateTime(
      lastDoneAt!.year,
      lastDoneAt!.month,
      lastDoneAt!.day,
    );
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // 下次执行日 = 上次执行日 + 间隔
    final nextDueDate = lastDate.add(Duration(days: intervalDays));

    // 计算差值
    return todayDate.difference(nextDueDate).inDays;
  }

  Task copyWith({
    String? title,
    TaskType? type,
    String? projectId,
    String? projectName,
    bool? isCompleted,
    int? intervalDays,
    DateTime? lastDoneAt,
    DateTime? deadline,
    bool? isAllDayDeadline,
    List<FocusSession>? sessions,
    // 特殊标记：传入 true 明确将 nullable 字段设为 null
    bool setProjectNull = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      // 如果 setProjectNull 为 true，强制赋 null；否则优先用新值，没有新值用旧值
      projectId: setProjectNull ? null : (projectId ?? this.projectId),
      projectName: setProjectNull ? null : (projectName ?? this.projectName),
      isCompleted: isCompleted ?? this.isCompleted,
      intervalDays: intervalDays ?? this.intervalDays,
      lastDoneAt: lastDoneAt ?? this.lastDoneAt,
      deadline: deadline ?? this.deadline,
      isAllDayDeadline: isAllDayDeadline ?? this.isAllDayDeadline,
      sessions: sessions ?? this.sessions,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'projectId': projectId,
    'projectName': projectName,
    'isCompleted': isCompleted,
    'intervalDays': intervalDays,
    'lastDoneAt': lastDoneAt?.toIso8601String(),
    'deadline': deadline?.toIso8601String(),
    'isAllDayDeadline': isAllDayDeadline,
    'sessions': sessions.map((s) => s.toJson()).toList(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    type: TaskTypeExt.fromJson(json['type']),
    projectId: json['projectId'],
    projectName: json['projectName'],
    isCompleted: json['isCompleted'] ?? false,
    intervalDays: json['intervalDays'] ?? 0,
    lastDoneAt: json['lastDoneAt'] != null
        ? DateTime.parse(json['lastDoneAt'])
        : null,
    deadline: json['deadline'] != null
        ? DateTime.parse(json['deadline'])
        : null,
    isAllDayDeadline: json['isAllDayDeadline'] ?? true,
    sessions:
        (json['sessions'] as List?)
            ?.map((e) => FocusSession.fromJson(e))
            .toList() ??
        [],
  );
}
