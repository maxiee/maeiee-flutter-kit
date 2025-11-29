import 'dart:async';

import 'package:get/get.dart';
import 'package:my_life_rpg/models/project.dart';
import 'package:uuid/uuid.dart';
import '../models/quest.dart';

class BlockState {
  final List<String> occupiedQuestIds; // 实际占用的任务 (Session)
  final List<String> deadlineQuestIds; // 在此截止的任务 (Deadline)

  BlockState({
    this.occupiedQuestIds = const [],
    this.deadlineQuestIds = const [],
  });

  bool get isEmpty => occupiedQuestIds.isEmpty && deadlineQuestIds.isEmpty;
}

class GameController extends GetxController {
  // 玩家状态 Mock
  final hp = '中'.obs; // HIGH, NORMAL, LOW
  final mpCurrent = 4.5.obs; // 剩余 4.5 小时
  final mpTotal = 6.0;

  // 1. 每日 XP (有效产出)
  final dailyXp = 0.obs;
  final tasksCompletedToday = 0.obs;

  // 选中的日期 (默认今天)
  final selectedDate = DateTime.now().obs;

  // 核心数据结构：一天的 96 个时间块的状态
  // 索引 0 = 00:00-00:15, 索引 95 = 23:45-24:00
  // Value: 任务ID (如果被占用) 或者 null
  final timeBlocks = List<BlockState>.generate(96, (_) => BlockState()).obs;

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

    // Mock Data Generator (适配新结构)
    quests.addAll([
      Quest(
        id: '1',
        title: '阅读 Flutter Engine 源码',
        type: QuestType.mission,
        projectId: 'p1',
        projectName: 'Flutter架构',
        sessions: [
          // 模拟昨天做了一次
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
        // 上次完成时间：sessions 里可以不用存具体的 session，只要 lastDoneAt 对就行
        lastDoneAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
    ]);
  }

  // 切换日期
  void changeDate(DateTime date) {
    selectedDate.value = date;
    _refreshTimeBlocks();
  }

  // 刷新时间块数据 (计算密集型，暂放在前端做)
  void _refreshTimeBlocks() {
    // 重置
    for (int i = 0; i < 96; i++) {
      timeBlocks[i] = BlockState(occupiedQuestIds: [], deadlineQuestIds: []);
    }

    final targetDate = selectedDate.value;

    // 遍历所有任务
    for (var q in quests) {
      if (q.deadline != null && !q.isAllDayDeadline) {
        // 只有精确时间才进格子
        if (q.deadline!.year == targetDate.year &&
            q.deadline!.month == targetDate.month &&
            q.deadline!.day == targetDate.day) {
          final blockIndex =
              (q.deadline!.hour * 4) + (q.deadline!.minute ~/ 15);
          if (blockIndex >= 0 && blockIndex < 96) {
            // 注意：这里需要先把旧状态拿出来，再 add，因为 timeBlocks 是 RxList，元素本身不是 Rx
            final oldState = timeBlocks[blockIndex];
            timeBlocks[blockIndex] = BlockState(
              occupiedQuestIds: oldState.occupiedQuestIds,
              deadlineQuestIds: [...oldState.deadlineQuestIds, q.id],
            );
          }
        }
      }
    }

    // 触发 UI 更新
    timeBlocks.refresh();
  }

  // 核心操作：完成任务
  void toggleQuestCompletion(String id) {
    final q = quests.firstWhere((e) => e.id == id);

    if (q.type == QuestType.daemon) {
      // 循环任务逻辑：
      // 不标记 isCompleted，而是重置时间戳
      // 为了让 UI 有反馈，我们可以设计一个 temporary state，但 MVP 简单处理：
      // 直接更新 lastDoneAt 为现在 -> 导致 dueDays 变负 -> 从 Active 列表消失
      // 必须创建一个新对象来触发 Rx 更新 (Quest 字段若是 final)
      final index = quests.indexOf(q);

      // 这里我们需要修改 Quest 模型支持 copyWith 或者重新构造
      // 假设我们直接修改 (如果 Quest 字段不是 final)
      // q.lastDoneAt = DateTime.now();

      // 如果字段是 final (推荐)，我们需要替换对象：
      quests[index] = Quest(
        id: q.id,
        title: q.title,
        type: q.type,
        projectId: q.projectId,
        projectName: q.projectName,
        isCompleted: false, // 永远为 false
        intervalDays: q.intervalDays,
        lastDoneAt: DateTime.now(), // <--- 核心：重置 CD
        sessions: q.sessions,
      );
    } else {
      // 普通任务逻辑：
      q.isCompleted = !q.isCompleted;
    }

    quests.refresh();
    // saveGame();
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
      for (var s in q.sessions) {
        // 判断 session 是否在今天 (简单判断 startTime)
        if (s.startTime.year == now.year &&
            s.startTime.month == now.month &&
            s.startTime.day == now.day) {
          effectiveMinutes += (s.durationSeconds / 60).round();
        }
      }
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

  // 新增：造物能力
  void addNewQuest({
    required String title,
    required QuestType type,
    Project? project,
    int interval = 0,
    // 新增这两个参数
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
      // 如果是 Daemon，新建时默认 lastDoneAt 设为过期状态
      lastDoneAt: type == QuestType.daemon
          ? DateTime.now().subtract(Duration(days: interval))
          : null,
      sessions: [],
      // 传递 Deadline
      deadline: deadline,
      isAllDayDeadline: isAllDayDeadline,
    );

    quests.add(newQuest);

    // 只有这样，新添加的 Deadline 才会映射到格子上
    _refreshTimeBlocks();

    // saveGame(); // 如果启用了持久化
  }

  // 提供给 SessionController 调用的刷新方法
  // 当 Session 结束时调用这个
  void onSessionFinished() {
    // 1. 刷新 Quest 列表状态 (触发 Rx 更新)
    quests.refresh();

    // 2. 重新计算今天的 XP 和时间熵
    _calculateTimeMetrics();

    // 3. 重新渲染时间矩阵 (因为刚产生了一个新 Session)
    _refreshTimeBlocks();

    // 4. 持久化数据 (如果有 DataService)
    // saveGame();

    // 5. 触发整个 Controller 的 update (如果有 GetBuilder 监听)
    update();
  }
}
