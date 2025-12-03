import 'package:get/get.dart';
import 'package:my_life_rpg/core/data/project_repository.dart';
import 'package:my_life_rpg/core/data/quest_repository.dart';
import 'package:my_life_rpg/core/domain/time_domain.dart';
import 'package:my_life_rpg/core/logic/project_logic.dart';
import 'package:my_life_rpg/core/utils/result.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/project.dart';

class QuestService extends GetxService {
  // 依赖注入 Repositories
  final QuestRepository _questRepo = Get.find();
  final ProjectRepository _projectRepo = Get.find();

  // 对外暴露的 Getters (只读)
  RxList<Task> get quests => _questRepo.listenable;
  List<Project> get projects => _projectRepo.listenable;

  // --- 业务逻辑 (Use Cases) ---

  // UseCase: 创建新任务
  Task addNewQuest({
    required String title,
    required TaskType type,
    Project? project,
    int interval = 0,
    DateTime? deadline,
    bool isAllDayDeadline = true,
  }) {
    final newQuest = Task(
      id: const Uuid().v4(),
      title: title,
      type: type,
      projectId: project?.id,
      projectName: project?.title,
      intervalDays: interval,
      // 业务规则：Daemon 默认初始化状态处理
      lastDoneAt: type == TaskType.routine
          ? DateTime.now().subtract(Duration(days: interval + 1))
          : null,
      sessions: [],
      deadline: deadline,
      isAllDayDeadline: isAllDayDeadline,
    );
    _questRepo.add(newQuest);
    return newQuest;
  }

  // UseCase: 更新任务状态
  void updateQuest(
    String id, {
    String? title,
    Project? project,
    DateTime? deadline,
    bool? isAllDayDeadline,
    int? interval,
  }) {
    final old = _questRepo.getById(id);
    if (old == null) return;

    final updated = Task(
      id: old.id,
      title: title ?? old.title,
      type: old.type,
      projectId: project?.id, // 允许 null (Standalone)
      projectName: project?.title,
      isCompleted: old.isCompleted,
      intervalDays: interval ?? old.intervalDays,
      lastDoneAt: old.lastDoneAt,
      deadline: deadline,
      isAllDayDeadline: isAllDayDeadline ?? old.isAllDayDeadline,
      sessions: old.sessions,
    );
    _questRepo.update(updated);
  }

  // UseCase: 删除任务
  void deleteQuest(String id) {
    _questRepo.delete(id);
  }

  // UseCase: 切换完成状态
  void toggleQuestCompletion(String id) {
    final q = _questRepo.getById(id);
    if (q == null) return;

    Task updated;
    if (q.type == TaskType.routine) {
      // 业务规则：Daemon 完成意味着刷新 CD
      updated = Task(
        id: q.id,
        title: q.title,
        type: q.type,
        projectId: q.projectId,
        projectName: q.projectName,
        isCompleted: false, // 永远为 false
        intervalDays: q.intervalDays,
        lastDoneAt: DateTime.now(), // 刷新
        sessions: q.sessions,
        deadline: q.deadline,
        isAllDayDeadline: q.isAllDayDeadline,
      );
    } else {
      // 业务规则：Mission 切换状态
      updated = Task(
        // 这里为了简单，其实 copyWith 方法会更好，但我们没生成
        id: q.id,
        title: q.title,
        type: q.type,
        projectId: q.projectId,
        projectName: q.projectName,
        isCompleted: !q.isCompleted,
        intervalDays: q.intervalDays,
        lastDoneAt: q.lastDoneAt,
        sessions: q.sessions,
        deadline: q.deadline,
        isAllDayDeadline: q.isAllDayDeadline,
      );
    }
    _questRepo.update(updated);
    _projectRepo.listenable.refresh(); // 触发项目进度刷新
  }

  // UseCase: 手动补录时间
  Result<void> manualAllocate(String questId, DateTime start, DateTime end) {
    final q = _questRepo.getById(questId);
    if (q == null) Result.err("Quest not found.");

    // 业务规则：防止跨天 (Service 层处理边界校验是合理的)
    DateTime safeEnd = end;
    if (end.day != start.day) {
      safeEnd = DateTime(start.year, start.month, start.day, 23, 59, 59);
    }

    // [重构点]: 调用 TimeDomain 进行碰撞检测
    // 需要先聚合所有现存的 Sessions
    final allSessions = quests.expand((q) => q.sessions).toList();

    // 业务规则：碰撞检测 (调用 Helper)
    if (TimeDomain.hasOverlap(start, safeEnd, allSessions)) {
      return Result.err("Time slot conflict detected!");
    }

    final session = FocusSession(
      startTime: start,
      endTime: safeEnd,
      durationSeconds: safeEnd.difference(start).inSeconds,
      logs: [TaskLog(createdAt: DateTime.now(), content: "Manual Allocation")],
    );

    q!.sessions.add(session); // 这里直接操作了内存对象的 List，如果换数据库需要深拷贝逻辑
    _questRepo.update(q); // 确保触发更新

    return Result.ok();
  }

  // 查 (获取今日活跃) - 这种 helper 方法可以放这
  List<Task> get activeMissions =>
      quests.where((q) => q.type == TaskType.todo && !q.isCompleted).toList();

  // 通知更新 (用于 SessionController 结束时手动触发)
  void notifyUpdate() {
    _questRepo.listenable.refresh();
    _projectRepo.listenable.refresh();
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

  // UseCase: Project CRUD
  void addProject(String title, String desc, double targetHours, int colorIdx) {
    _projectRepo.add(
      Project(
        id: const Uuid().v4(),
        title: title,
        description: desc,
        targetHours: targetHours,
        colorIndex: colorIdx,
      ),
    );
  }

  void updateProject(
    String id, {
    String? title,
    String? desc,
    double? targetHours,
    int? colorIdx,
  }) {
    final p = _projectRepo.getById(id);
    if (p == null) return;

    // 1. 检查标题是否改变
    final bool nameChanged = title != null && title != p.title;

    // 2. 更新项目本身
    p.title = title ?? p.title;
    p.description = desc ?? p.description;
    p.targetHours = targetHours ?? p.targetHours;
    p.colorIndex = colorIdx ?? p.colorIndex;
    _projectRepo.update(p); // 触发项目列表刷新

    // 3. [新增] 级联更新关联任务的 ProjectName
    if (nameChanged) {
      final relatedQuests = quests.where((q) => q.projectId == id).toList();
      for (var q in relatedQuests) {
        final updatedQ = q.copyWith(projectName: p.title);
        _questRepo.update(updatedQ);
      }
      // 触发任务列表刷新 (因为任务的显示属性变了)
      _questRepo.listenable.refresh();
    }
  }

  // 删
  void deleteProject(String id) {
    // 1. [新增] 找到所有关联任务
    final relatedQuests = quests.where((q) => q.projectId == id).toList();

    // 2. [新增] 解绑 (Detach)
    for (var q in relatedQuests) {
      final updatedQ = q.copyWith(setProjectNull: true);
      _questRepo.update(updatedQ);
    }

    // 3. 删除项目
    _projectRepo.delete(id);

    // 4. 强制刷新列表 (UI更新)
    _questRepo.listenable.refresh();
  }

  // UseCase: 获取项目进度
  double getProjectProgress(String projectId) {
    final p = _projectRepo.getById(projectId);
    if (p == null) return 0.0;

    // 获取该项目关联的任务
    final relatedQuests = quests
        .where((q) => q.projectId == projectId)
        .toList();

    // [重构点]: 委托给 ProjectLogic 计算
    return ProjectLogic.calculateProgress(p, relatedQuests);
  }

  // UseCase: 获取 Session
  ({Task quest, FocusSession session})? getSessionById(String sessionId) {
    for (var q in quests) {
      for (var s in q.sessions) {
        if (s.id == sessionId) return (quest: q, session: s);
      }
    }
    return null;
  }

  // UseCase: 删除 Session
  void deleteSession(String questId, String sessionId) {
    final q = _questRepo.getById(questId);
    if (q == null) return;
    q.sessions.removeWhere((s) => s.id == sessionId);
    _questRepo.listenable.refresh();
  }
}
