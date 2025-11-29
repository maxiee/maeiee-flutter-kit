import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/quest.dart';
import '../models/project.dart';

class QuestService extends GetxService {
  final quests = <Quest>[].obs;
  final projects = <Project>[].obs;

  // 增
  Quest addNewQuest({
    required String title,
    required QuestType type,
    Project? project,
    int interval = 0,
    DateTime? deadline,
    bool isAllDayDeadline = true,
  }) {
    final newQuest = Quest(
      id: const Uuid().v4(),
      title: title,
      type: type,
      projectId: project?.id,
      projectName: project?.title,
      intervalDays: interval,
      // 如果是 Daemon，新建时如果是刚创建，lastDoneAt 设为 null 或者 很久以前，
      // 这里为了方便，如果 interval>0，设为过去，让它立刻变为 Active
      lastDoneAt: type == QuestType.daemon
          ? DateTime.now().subtract(Duration(days: interval + 1))
          : null,
      sessions: [],
      deadline: deadline,
      isAllDayDeadline: isAllDayDeadline,
    );
    quests.add(newQuest);
    return newQuest;
  }

  // 改 (完成/取消)
  void toggleQuestCompletion(String id) {
    final q = quests.firstWhere((e) => e.id == id);
    if (q.type == QuestType.daemon) {
      // 循环任务逻辑：重置对象以触发更新 (如果是 final)
      final index = quests.indexOf(q);
      quests[index] = Quest(
        id: q.id,
        title: q.title,
        type: q.type,
        projectId: q.projectId,
        projectName: q.projectName,
        isCompleted: false, // Daemon 永远不会“完成”，只是刷新 CD
        intervalDays: q.intervalDays,
        lastDoneAt: DateTime.now(), // 更新最后完成时间
        sessions: q.sessions,
        deadline: q.deadline,
        isAllDayDeadline: q.isAllDayDeadline,
      );
    } else {
      q.isCompleted = !q.isCompleted;
    }
    quests.refresh();
    // 项目进度可能会变，需要 UI 监听
    projects.refresh();
  }

  // 改 (补录)
  void manualAllocate(String questId, DateTime start, DateTime end) {
    final now = DateTime.now();

    // [修改点]：禁止补录未来
    if (start.isAfter(now)) {
      Get.snackbar("Error", "不能补录未来的时间");
      return;
    }

    // 1. 预检
    if (start.isAfter(end)) return; // 基础逻辑

    // 如果 End 超过了 Now，强制截断
    DateTime actualEnd = end;
    if (end.isAfter(now)) {
      actualEnd = now;
    }

    // 2. [修改点] 碰撞检测
    if (hasTimeOverlap(start, actualEnd)) {
      Get.snackbar(
        "Time Conflict",
        "这段时间已经有记录了，请先调整旧记录。",
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    final quest = quests.firstWhereOrNull((q) => q.id == questId);
    if (quest == null) return;

    // [改进]：防止跨天补录导致的显示 BUG (强制截断到当天 23:59:59)
    DateTime safeEnd = end;
    if (end.day != start.day) {
      safeEnd = DateTime(start.year, start.month, start.day, 23, 59, 59);
    }

    final duration = safeEnd.difference(start).inSeconds;
    final session = QuestSession(
      startTime: start,
      endTime: safeEnd,
      durationSeconds: duration,
      logs: [
        QuestLog(
          createdAt: DateTime.now(),
          content: "手动补录 [Matrix]",
          type: LogType.normal,
        ),
      ],
    );
    quest.sessions.add(session);
    quests.refresh();
  }

  // 查 (获取今日活跃) - 这种 helper 方法可以放这
  List<Quest> get activeMissions => quests
      .where((q) => q.type == QuestType.mission && !q.isCompleted)
      .toList();

  // 新增：通用的数据更新通知
  // 当 SessionController 修改了 Quest 内部数据（如添加 session）后调用此方法
  void notifyUpdate() {
    quests.refresh();
    projects.refresh();
    // 这里未来可以加 saveGame()
  }

  bool hasTimeOverlap(
    DateTime start,
    DateTime end, {
    String? excludeSessionId,
  }) {
    for (var q in quests) {
      for (var s in q.sessions) {
        if (s.id == excludeSessionId) continue;

        // 计算 Session 的实际结束时间
        DateTime sEnd = s.endTime ?? DateTime.now(); // 如果正在进行，暂认为到当前时间

        // 经典的区间重叠判断: (StartA < EndB) and (EndA > StartB)
        if (start.isBefore(sEnd) && end.isAfter(s.startTime)) {
          return true; // 发生碰撞
        }
      }
    }
    return false;
  }

  // 增
  void addProject(String title, String desc, double targetHours, int colorIdx) {
    projects.add(
      Project(
        id: const Uuid().v4(),
        title: title,
        description: desc,
        targetHours: targetHours,
        colorIndex: colorIdx,
      ),
    );
  }

  // 改
  void updateProject(
    String id, {
    String? title,
    String? desc,
    double? targetHours,
    int? colorIdx,
  }) {
    final p = projects.firstWhereOrNull((p) => p.id == id);
    if (p == null) return;

    // 这里因为是 class 对象引用，直接改属性即可
    // 但为了触发 Obx 更新，最好是 replace 或者 call refresh
    if (title != null) p.title = title;
    if (desc != null) p.description = desc;
    if (targetHours != null) p.targetHours = targetHours;
    if (colorIdx != null) p.colorIndex = colorIdx;

    projects.refresh();
  }

  // 删
  void deleteProject(String id) {
    // 1. 删除项目
    projects.removeWhere((p) => p.id == id);
    // 2. 解绑任务 (将该项目下的任务变为无归属)
    for (var q in quests) {
      if (q.projectId == id) {
        // 这一步比较麻烦，因为 Quest 是 final 字段较多
        // 简单处理：我们不改 Quest 模型了，显示的时候查不到 Project 就当 Standalone
        // 或者你需要遍历 quests 修改 projectId 为 null
      }
    }
  }

  // 升级进度计算
  double getProjectProgress(String projectId) {
    final p = projects.firstWhereOrNull((x) => x.id == projectId);
    if (p == null) return 0.0;

    final projectQuests = quests
        .where((q) => q.projectId == projectId)
        .toList();

    if (p.targetHours > 0) {
      // 基于时间计算
      int totalSeconds = 0;
      for (var q in projectQuests) {
        totalSeconds += q.totalDurationSeconds;
      }
      double currentHours = totalSeconds / 3600;
      return (currentHours / p.targetHours).clamp(0.0, 1.0);
    } else {
      // 基于任务数计算 (旧逻辑)
      if (projectQuests.isEmpty) return 0.0;
      final missionQuests = projectQuests
          .where((q) => q.type == QuestType.mission)
          .toList();
      if (missionQuests.isEmpty) return 0.0;
      final completed = missionQuests.where((q) => q.isCompleted).length;
      return completed / missionQuests.length;
    }
  }

  // 新增：Mock 数据加载
  void loadMockData() {
    projects.addAll([
      Project(
        id: 'p1',
        title: 'Flutter架构演进',
        description: '技术专家之路',
      ), // progress 由 UI 动态获取
      Project(id: 'p2', title: '独立开发: NEXUS', description: '副业破局点'),
    ]);

    quests.addAll([
      // P1 的任务
      Quest(
        id: '1',
        title: '阅读 RenderObject 源码',
        type: QuestType.mission,
        projectId: 'p1',
        projectName: 'Flutter架构',
        isCompleted: true, // 已完成
      ),
      Quest(
        id: '2',
        title: '重构 TimeService',
        type: QuestType.mission,
        projectId: 'p1',
        projectName: 'Flutter架构',
        isCompleted: false, // 未完成
      ),

      // Daemon
      Quest(
        id: '4',
        title: '清理厨房水槽',
        type: QuestType.daemon,
        intervalDays: 1, // 每天
        lastDoneAt: DateTime.now().subtract(
          const Duration(days: 2),
        ), // 2天前做的，今天该做了
      ),
    ]);
  }
}
