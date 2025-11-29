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
      lastDoneAt: type == QuestType.daemon
          ? DateTime.now().subtract(Duration(days: interval))
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
        isCompleted: false,
        intervalDays: q.intervalDays,
        lastDoneAt: DateTime.now(), // 重置 CD
        sessions: q.sessions,
        deadline: q.deadline,
        isAllDayDeadline: q.isAllDayDeadline,
      );
    } else {
      q.isCompleted = !q.isCompleted;
    }
    quests.refresh();
  }

  // 改 (补录)
  void manualAllocate(String questId, DateTime start, DateTime end) {
    final quest = quests.firstWhereOrNull((q) => q.id == questId);
    if (quest == null) return;
    final duration = end.difference(start).inSeconds;
    final session = QuestSession(
      startTime: start,
      endTime: end,
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
    // 这里未来可以加 saveGame()
  }

  // 新增：Mock 数据加载
  void loadMockData() {
    projects.addAll([
      Project(
        id: 'p1',
        title: 'Flutter架构演进',
        description: '技术专家之路',
        progress: 0.4,
      ),
      Project(
        id: 'p2',
        title: '独立开发: NEXUS',
        description: '副业破局点',
        progress: 0.1,
      ),
      Project(id: 'p3', title: '著作: TMB', description: '影响力建设', progress: 0.2),
    ]);

    quests.addAll([
      Quest(
        id: '1',
        title: '阅读 Flutter Engine 源码',
        type: QuestType.mission,
        projectId: 'p1',
        projectName: 'Flutter架构',
        sessions: [
          QuestSession(
            startTime: DateTime.now().subtract(
              const Duration(days: 1, hours: 2),
            ),
            endTime: DateTime.now().subtract(const Duration(days: 1)),
            durationSeconds: 7200,
            logs: [
              QuestLog(
                createdAt: DateTime.now().subtract(const Duration(days: 1)),
                content: "阅读了 RenderObject 源码",
              ),
            ],
          ),
        ],
      ),
      Quest(
        id: '4',
        title: '清理厨房水槽',
        type: QuestType.daemon,
        intervalDays: 21,
        lastDoneAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
    ]);
  }
}
