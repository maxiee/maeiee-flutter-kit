import 'dart:async';

import 'package:get/get.dart';
import 'package:my_life_rpg/models/project.dart';
import '../models/quest.dart';

class GameController extends GetxController {
  // 玩家状态 Mock
  final hp = '中'.obs; // HIGH, NORMAL, LOW
  final mpCurrent = 4.5.obs; // 剩余 4.5 小时
  final mpTotal = 6.0;

  // 1. 每日 XP (有效产出)
  final dailyXp = 0.obs;
  final tasksCompletedToday = 0.obs;

  // 2. 时间感知 (Time Perception)
  final dayStartTime = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    8,
    0,
  ); // 早上 08:00
  final dayEndTime = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day + 1,
    1,
    0,
  ); // 次日 01:00

  // 实时状态
  final timeToSleep = ''.obs; // 距离睡觉倒计时
  final effectiveRatio = 0.0.obs; // 有效时间占比 (0.0 - 1.0)
  final entropyRatio = 0.0.obs; // 熵(浪费/未知)时间占比
  final futureRatio = 1.0.obs; // 未来时间占比

  Timer? _heartbeat;

  final projects = <Project>[].obs; // 新增
  final quests = <Quest>[].obs;

  @override
  void onInit() {
    super.onInit();

    // 启动心跳：每分钟刷新一次时间感知
    _heartbeat = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _calculateTimeMetrics(),
    );
    _calculateTimeMetrics(); // 立即执行一次

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

  // 核心算法：计算当天的时间分布
  void _calculateTimeMetrics() {
    final now = DateTime.now();

    // 1. 计算总跨度 (比如 08:00 - 01:00 = 17小时)
    final totalDaySpan = dayEndTime.difference(dayStartTime).inMinutes;
    if (totalDaySpan <= 0) return;

    // 2. 计算已流逝时间 (Past)
    final elapsedMinutes = now
        .difference(dayStartTime)
        .inMinutes
        .clamp(0, totalDaySpan);

    // 3. 计算有效时间 (Effective) - 遍历今天所有 Quest 的 totalDuration
    // *注意：为了 MVP，这里我们暂时假设 totalDurationSeconds 都是今天产生的。
    // *实际项目中，QuestLog 应该包含 duration，这里累加今天的 Log duration。
    int effectiveMinutes = 0;
    for (var q in quests) {
      // 简单模拟：假设总时长的 10% 是今天做的 (仅作 Mock 展示)
      effectiveMinutes += (q.totalDurationSeconds / 60 * 0.1).round();
    }

    // 4. 计算熵 (Entropy / Wasted)
    // 熵 = 流逝时间 - 有效时间
    int entropyMinutes = elapsedMinutes - effectiveMinutes;
    if (entropyMinutes < 0) entropyMinutes = 0; // 避免负数

    // 5. 更新比率 (用于 UI 进度条)
    effectiveRatio.value = effectiveMinutes / totalDaySpan;
    entropyRatio.value = entropyMinutes / totalDaySpan;
    futureRatio.value = (totalDaySpan - elapsedMinutes) / totalDaySpan;

    // 6. 倒计时
    final diff = dayEndTime.difference(now);
    if (diff.isNegative) {
      timeToSleep.value = "OVERTIME";
    } else {
      timeToSleep.value =
          "-${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}";
    }

    // 7. 计算 XP
    // 简单公式：1分钟有效时间 = 1 XP，完成一个任务 = 50 XP
    int completedCount = quests
        .where((q) => q.isCompleted)
        .length; // 实际应判断完成时间是否是今天
    tasksCompletedToday.value = completedCount;
    dailyXp.value = effectiveMinutes + (completedCount * 50);
  }
}
