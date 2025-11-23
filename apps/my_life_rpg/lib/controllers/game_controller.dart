import 'package:get/get.dart';
import 'package:my_life_rpg/models/project.dart';
import '../models/quest.dart';

class GameController extends GetxController {
  // 玩家状态 Mock
  final hp = '中'.obs; // HIGH, NORMAL, LOW
  final mpCurrent = 4.5.obs; // 剩余 4.5 小时
  final mpTotal = 6.0;

  final projects = <Project>[].obs; // 新增
  final quests = <Quest>[].obs;

  @override
  void onInit() {
    super.onInit();

    // 1. 初始化项目 (战役)
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

    // 2. 初始化任务 (Missions & Daemons)
    quests.addAll([
      // 属于 p1 的任务
      Quest(
        id: '1',
        title: '阅读 Flutter Engine 源码 (RenderObject)',
        type: QuestType.mission,
        projectId: 'p1',
        projectName: 'Flutter架构',
      ),
      // 属于 p2 的任务
      Quest(
        id: '2',
        title: '实现 Session View 逻辑',
        type: QuestType.mission,
        projectId: 'p2',
        projectName: 'NEXUS',
      ),
      // 无主任务
      Quest(id: '3', title: '给 Judy 买花', type: QuestType.mission),

      // Daemon 保持不变
      Quest(
        id: '4',
        title: '清理厨房水槽',
        type: QuestType.daemon,
        intervalDays: 21,
        lastDoneAt: DateTime.now().subtract(Duration(days: 25)),
      ),
    ]);
  }

  // 核心操作：完成任务
  void toggleQuestCompletion(String id) {
    final q = quests.firstWhere((e) => e.id == id);
    q.isCompleted = !q.isCompleted;
    quests.refresh();
  }
}
