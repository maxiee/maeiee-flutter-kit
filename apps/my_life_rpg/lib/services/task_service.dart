import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/data/direction_repository.dart';
import 'package:my_life_rpg/core/data/project_repository.dart';
import 'package:my_life_rpg/core/data/task_repository.dart';
import 'package:my_life_rpg/core/domain/time_domain.dart';
import 'package:my_life_rpg/core/logic/project_logic.dart';
import 'package:my_life_rpg/core/utils/result.dart';
import 'package:my_life_rpg/models/direction.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/project.dart';

class TaskService extends GetxService {
  // 依赖注入 Repositories
  final TaskRepository _taskRepo = Get.find();
  final ProjectRepository _projectRepo = Get.find();
  final DirectionRepository _dirRepo = Get.find();

  // 对外暴露的 Getters (只读)
  RxList<Task> get tasks => _taskRepo.listenable;
  List<Project> get projects => _projectRepo.listenable;
  List<Direction> get directions => _dirRepo.listenable;

  // --- 业务逻辑 (Use Cases) ---

  // UseCase: 创建新任务
  Task addNewTask({
    required String title,
    required TaskType type,
    Project? project,
    int interval = 0,
    DateTime? deadline,
    bool isAllDayDeadline = true,
    List<SubTask>? checklist,
  }) {
    final newTask = Task(
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
      checklist: checklist ?? [],
    );
    _taskRepo.add(newTask);
    return newTask;
  }

  // UseCase: 更新任务状态
  void updateTask(
    String id, {
    String? title,
    Project? project,
    DateTime? deadline,
    bool? isAllDayDeadline,
    int? interval,
    List<SubTask>? checklist,
  }) {
    final old = _taskRepo.getById(id);
    if (old == null) return;

    final updated = old.copyWith(
      title: title,
      projectId: project?.id,
      projectName: project?.title,
      deadline: deadline,
      isAllDayDeadline: isAllDayDeadline,
      intervalDays: interval,
      setProjectNull: project == null && title != null,
      checklist: checklist ?? old.checklist,
    );

    _taskRepo.update(updated);
  }

  // UseCase: 删除任务
  void deleteTask(String id) {
    _taskRepo.delete(id);
  }

  // UseCase: 切换完成状态
  void toggleTaskCompletion(String id) {
    final q = _taskRepo.getById(id);
    if (q == null) return;

    // 业务逻辑下沉到 Model，Service 变得极其干净
    final updated = q.onToggle();

    _taskRepo.update(updated);
    _projectRepo.listenable.refresh(); // 触发项目进度刷新
  }

  // UseCase: 手动补录时间
  Result<void> manualAllocate(String taskId, DateTime start, DateTime end) {
    final q = _taskRepo.getById(taskId);
    if (q == null) Result.err("Quest not found.");

    // 业务规则：防止跨天 (Service 层处理边界校验是合理的)
    DateTime safeEnd = end;
    if (end.day != start.day) {
      safeEnd = DateTime(start.year, start.month, start.day, 23, 59, 59);
    }

    // [重构点]: 调用 TimeDomain 进行碰撞检测
    // 需要先聚合所有现存的 Sessions
    final allSessions = tasks.expand((q) => q.sessions).toList();

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
    _taskRepo.update(q); // 确保触发更新

    return Result.ok();
  }

  // 查 (获取今日活跃) - 这种 helper 方法可以放这
  List<Task> get activeMissions =>
      tasks.where((q) => q.type == TaskType.todo && !q.isCompleted).toList();

  // 通知更新 (用于 SessionController 结束时手动触发)
  void notifyUpdate() {
    _taskRepo.listenable.refresh();
    _projectRepo.listenable.refresh();
  }

  bool hasTimeOverlap(
    DateTime start,
    DateTime end, {
    String? excludeSessionId,
  }) {
    for (var q in tasks) {
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

  // --- Direction CRUD [新增] ---

  void addDirection(String title, String desc, int colorIdx, IconData icon) {
    _dirRepo.add(
      Direction(
        id: const Uuid().v4(),
        title: title,
        description: desc,
        colorIndex: colorIdx,
        iconPoint: icon.codePoint,
      ),
    );
  }

  void updateDirection(
    String id, {
    String? title,
    String? desc,
    int? colorIdx,
    IconData? icon,
  }) {
    final d = _dirRepo.getById(id);
    if (d == null) return;

    d.title = title ?? d.title;
    d.description = desc ?? d.description;
    d.colorIndex = colorIdx ?? d.colorIndex;
    if (icon != null) d.iconPoint = icon.codePoint;

    _dirRepo.update(d);
  }

  void deleteDirection(String id) {
    // 级联处理：找到该 Direction 下的所有 Project
    final relatedProjects = projects.where((p) => p.directionId == id).toList();

    // 策略：将这些 Project 的 directionId 设为 null (变为 Standalone)，而不是删除项目
    for (var p in relatedProjects) {
      updateProject(p.id, directionId: null, setDirectionNull: true);
    }

    _dirRepo.delete(id);
  }

  // UseCase: Project CRUD
  void addProject(
    String title,
    String desc,
    double targetHours,
    int colorIdx, {
    String? directionId,
  }) {
    _projectRepo.add(
      Project(
        id: const Uuid().v4(),
        title: title,
        description: desc,
        targetHours: targetHours,
        colorIndex: colorIdx,
        directionId: directionId,
      ),
    );
  }

  void updateProject(
    String id, {
    String? title,
    String? desc,
    double? targetHours,
    int? colorIdx,
    String? directionId,
    bool setDirectionNull = false,
  }) {
    final p = _projectRepo.getById(id);
    if (p == null) return;

    final bool nameChanged = title != null && title != p.title;

    p.title = title ?? p.title;
    p.description = desc ?? p.description;
    p.targetHours = targetHours ?? p.targetHours;
    p.colorIndex = colorIdx ?? p.colorIndex;

    // [新增] 关联更新
    if (setDirectionNull) {
      p.directionId = null;
    } else if (directionId != null) {
      p.directionId = directionId;
    }

    _projectRepo.update(p);

    if (nameChanged) {
      final relatedQuests = tasks.where((q) => q.projectId == id).toList();
      for (var q in relatedQuests) {
        final updatedQ = q.copyWith(projectName: p.title);
        _taskRepo.update(updatedQ);
      }
      _taskRepo.listenable.refresh();
    }
  }

  // 删
  void deleteProject(String id) {
    // 1. 找到所有关联任务
    final relatedQuests = tasks.where((q) => q.projectId == id).toList();

    // 2. 解绑 (Detach)
    for (var q in relatedQuests) {
      final updatedQ = q.copyWith(setProjectNull: true);
      _taskRepo.update(updatedQ);
    }

    // 3. 删除项目
    _projectRepo.delete(id);

    // 4. 强制刷新列表 (UI更新)
    _taskRepo.listenable.refresh();
  }

  // UseCase: 获取项目进度
  double getProjectProgress(String projectId) {
    final p = _projectRepo.getById(projectId);
    if (p == null) return 0.0;

    // 获取该项目关联的任务
    final relatedQuests = tasks.where((q) => q.projectId == projectId).toList();

    // [重构点]: 委托给 ProjectLogic 计算
    return ProjectLogic.calculateProgress(p, relatedQuests);
  }

  // UseCase: 获取 Session
  ({Task task, FocusSession session})? getSessionById(String sessionId) {
    for (var q in tasks) {
      for (var s in q.sessions) {
        if (s.id == sessionId) return (task: q, session: s);
      }
    }
    return null;
  }

  // UseCase: 删除 Session
  void deleteSession(String questId, String sessionId) {
    final q = _taskRepo.getById(questId);
    if (q == null) return;
    q.sessions.removeWhere((s) => s.id == sessionId);
    _taskRepo.listenable.refresh();
  }

  /// 智能分配时间：支持 任务ID / 项目ID / 系统类别
  /// [targetId]: 可能是 taskId, projectId, 或 categoryTag
  /// [mode]: 0=Task, 1=Project, 2=System
  Result<void> quickAllocate({
    required String targetId,
    required int mode,
    required DateTime start,
    required DateTime end,
    String? customTitle, // 如果是新建任务模式
  }) {
    Task? targetTask;

    // 模式 A: 明确的任务 (Task)
    if (mode == 0) {
      targetTask = _taskRepo.getById(targetId);
    }
    // 模式 B: 项目 (Project) -> 寻找/创建该项目的 "General Work" 容器
    else if (mode == 1) {
      final project = _projectRepo.getById(targetId);
      if (project == null) return Result.err("Project not found");

      // 尝试寻找该项目下的通用容器任务
      // 命名约定：标题就是项目名，或者叫 "General Work"
      // 只查找 "未完成" 的 General Work
      // 这样如果你把之前的 General Work 勾掉了，或者重命名了，这里就会找不到，从而触发下面的创建逻辑
      targetTask = tasks.firstWhereOrNull(
        (t) =>
            t.projectId == project.id &&
            t.title == "General Work" &&
            !t.isCompleted,
      );

      // 如果没找到，创建一个
      targetTask ??= addNewTask(
        title: "General Work", // 通用工作容器
        type: TaskType.todo,
        project: project,
        isAllDayDeadline: true, // 不设具体Deadline
      );
    }
    // 模式 C: 系统类别 (System) -> 寻找/创建全局容器
    else if (mode == 2) {
      // targetId 传进来的是 "REST", "CHAOS", "LEARNING" 等标签
      final title = targetId;

      targetTask = tasks.firstWhereOrNull(
        (t) => t.projectId == null && t.title == title,
      );

      targetTask ??= addNewTask(
        title: title,
        type: TaskType.todo, // 也可以定义个新的 Type，暂且用 Todo
      );
    }

    if (targetTask == null) {
      // 兜底：如果是新建模式 (New Task)
      if (customTitle != null && customTitle.isNotEmpty) {
        targetTask = addNewTask(title: customTitle, type: TaskType.todo);
      } else {
        return Result.err("Target unresolvable.");
      }
    }

    // 执行分配
    return manualAllocate(targetTask.id, start, end);
  }
}
