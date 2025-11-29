import 'dart:async';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/domain/time_domain.dart';
import 'package:my_life_rpg/core/logic/level_logic.dart';
import 'package:my_life_rpg/core/logic/xp_strategy.dart';
import 'package:my_life_rpg/models/block_state.dart';
import 'package:my_life_rpg/models/quest.dart';
import 'quest_service.dart';

class TimeService extends GetxService {
  final QuestService _questService = Get.find(); // 依赖注入

  // [新增] 玩家等级状态
  final playerLevel = 1.obs;
  int _previousLevel = 1; // 内部状态，不需要响应式

  // [新增] 升级事件流 (使用 GetX 的 Worker 机制也可以，这里用 Stream 更纯粹)
  // 或者简单点，直接暴露一个 RxBool showLevelUp = false.obs;
  // 考虑到弹窗是一次性的，用 Callback 或者 Worker 比较合适。
  // 我们选择在 Service 里不直接做 UI 操作，而是暴露一个 Stream/Callback 给 UI 层监听。
  final _levelUpEvent = Rxn<int>(); // 当升级时，这里会发射新等级
  Stream<int?> get onLevelUp => _levelUpEvent.stream;

  final playerTitle = "NOVICE".obs;
  final levelProgress = 0.0.obs;
  final totalXp = 0.obs; // 历史总 XP

  // 状态
  final selectedDate = DateTime.now().obs;
  final timeBlocks = <BlockState>[].obs;

  // 指标
  final dailyXp = 0.obs;
  final timeRemainingStr = ''.obs; // 改名：不再叫 timeToSleep
  final effectiveRatio = 0.0.obs;
  final entropyRatio = 0.0.obs;
  final futureRatio = 1.0.obs;

  // 1. 每日 XP (有效产出)
  final tasksCompletedToday = 0.obs;

  Timer? _heartbeat;

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

  @override
  void onInit() {
    super.onInit();

    // 初始化空数据，防止 UI 渲染越界
    timeBlocks.value = List.generate(96, (_) => BlockState.empty());

    // 监听：任务列表变化 或 日期选择变化 都要刷新
    ever(_questService.quests, (_) => refreshAll());

    _heartbeat = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _calculateTimeMetrics(),
    );
    _calculateTimeMetrics();
  }

  void refreshAll() {
    _calculateTimeMetrics();
    _refreshTimeBlocks();
  }

  void changeDate(DateTime date) {
    selectedDate.value = date;
    // _refreshTimeBlocks 会被 ever 触发，但 calculateTimeMetrics 需要手动触发一下以防万一
    _refreshTimeBlocks();
  }

  // [修改点]：自然日核心算法
  void _calculateTimeMetrics() {
    final now = DateTime.now();
    final targetDate = selectedDate.value;

    // 判断我们是否在查看“今天”
    final isViewingToday =
        (targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day);

    // 1. 全天固定 1440 分钟 (24小时)
    const totalDayMinutes = 1440;

    // 2. 计算已流逝时间 (Past)
    int elapsedMinutes = 0;
    if (isViewingToday) {
      elapsedMinutes = (now.hour * 60) + now.minute;
    } else if (targetDate.isBefore(now)) {
      elapsedMinutes = 1440; // 过去的日子，全部流逝
    } else {
      elapsedMinutes = 0; // 未来的日子，尚未流逝
    }

    // 3. 计算有效时间 (Effective)
    // 遍历所有任务，找出落在 targetDate 这一天的 Session
    int effectiveSeconds = 0;

    final allSessions = _questService.quests.expand((q) => q.sessions).toList();

    effectiveSeconds = TimeDomain.calculateEffectiveSeconds(
      allSessions,
      targetDate,
    );
    final effectiveMinutes = effectiveSeconds ~/ 60;

    // 4. 计算熵 (Entropy)
    // 熵 = 流逝的时间 - 有效记录的时间
    int entropyMinutes = elapsedMinutes - effectiveMinutes;
    if (entropyMinutes < 0) entropyMinutes = 0;

    // 5. 更新比率
    effectiveRatio.value = effectiveMinutes / totalDayMinutes;
    entropyRatio.value = entropyMinutes / totalDayMinutes;
    futureRatio.value = (totalDayMinutes - elapsedMinutes) / totalDayMinutes;

    // 6. 倒计时 (距离当天结束)
    if (isViewingToday) {
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final diff = endOfDay.difference(now);
      timeRemainingStr.value =
          "-${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}";
    } else {
      timeRemainingStr.value = "N/A";
    }

    // 7. 计算 XP
    // 统计今天完成的任务 (基于 lastDoneAt 或 完成状态)
    // 这里简单处理：统计所有今天有产出的 Mission 视为活跃
    int activeMissionsCount = 0;
    // 更准确的逻辑：
    // tasksCompletedToday 应该统计 "completedTime" 在今天的。
    // 由于 Quest 模型目前只有 isCompleted 状态，没有 completedAt，暂时用 effectiveMinutes 估算 XP

    // A. 今日 XP
    // 使用策略计算有效时长的产出 (假设今日未获得额外 Bonus)
    dailyXp.value = StandardXpStrategy.instance.calculateBase(effectiveSeconds);

    // 简单统计：多少个任务在今天有投入
    tasksCompletedToday.value = _questService.quests.where((q) {
      return q.sessions.any(
        (s) =>
            s.startTime.year == targetDate.year &&
            s.startTime.month == targetDate.month &&
            s.startTime.day == targetDate.day,
      );
    }).length;

    // [新增]：计算历史总 XP (遍历所有 Quest 的所有 Session)
    // 这是一个全量遍历，数据量大时会有性能问题，但 MVP 阶段内存里几千条 Log 没问题。
    int grandTotalSeconds = 0;
    for (var q in _questService.quests) {
      // 累加所有 Session 时长
      grandTotalSeconds += q.totalDurationSeconds;

      // 注意：正在进行的 Session 也要算进去 (实时反馈)
      // q.sessions 里的最后一个如果是进行中，totalDurationSeconds 可能还没更新(取决于实现)
      // 为了稳妥，我们手动处理进行中的 Session
      for (var s in q.sessions) {
        if (s.endTime == null) {
          // 补上这部分的差值，因为 q.totalDurationSeconds 可能只存了 0 或旧值
          final currentDuration = DateTime.now()
              .difference(s.startTime)
              .inSeconds;
          // 减去 s.durationSeconds 是为了防止重复计算(如果它存了的话)
          grandTotalSeconds += (currentDuration - s.durationSeconds);
        }
      }
    }

    // B. 历史总 XP (遍历所有 Quest)
    int grandTotalXp = 0;

    for (var q in _questService.quests) {
      // 我们需要细粒度计算，因为有些 Quest 完成了(有Bonus)，有些没完成
      // 但目前 Model 里 Session 没有存 XP，Quest 只有 isCompleted 状态

      // 1. 计算该任务所有 Session 的基础 XP
      int questSeconds = q.totalDurationSeconds;

      // 处理正在进行中的 Session (实时反馈)
      for (var s in q.sessions) {
        if (s.endTime == null) {
          final currentDuration = DateTime.now()
              .difference(s.startTime)
              .inSeconds;
          questSeconds += (currentDuration - s.durationSeconds);
        }
      }

      // 累加基础分
      grandTotalXp += StandardXpStrategy.instance.calculateBase(questSeconds);

      // 2. 累加额外奖励 (Bonus)
      // 如果任务被标记为完成，且不是 Daemon (Daemon 的完成逻辑比较特殊，暂时不计一次性Bonus，或者每次 interval 算一次?)
      // 这里简化处理：遵循标准策略，如果是 Mission 且 Completed，加分
      if (q.type == QuestType.mission && q.isCompleted) {
        // 为了获取 Bonus，我们可以用 calculate(0, true) 减去 calculateBase(0)
        // 或者直接调用 calculate(0, true) 获取纯 Bonus
        grandTotalXp += StandardXpStrategy.instance.calculate(0, true);
      }
    }

    totalXp.value = grandTotalXp;

    // 计算等级
    final levelInfo = LevelLogic.calculate(grandTotalXp);

    // [新增] 升级检测逻辑
    // 只有当新等级 > 旧等级，并且不是初始化阶段(旧等级=1且新等级=1算初始化，或者旧等级=0)时
    // 为了防止启动时就把之前升过的级弹出来，我们需要一个标志位 or 初始同步
    if (_previousLevel != 0 && levelInfo.level > _previousLevel) {
      // 触发升级事件！
      _levelUpEvent.value = levelInfo.level;
      // 重置事件 (可选，防止重复触发，但 Stream 不需要)
    }

    // 更新状态
    _previousLevel = playerLevel.value; // 先保存旧的(或者这一步放在if前面？)
    // 修正：应该先保存当前作为旧的，再更新新的吗？
    // 正确逻辑：
    // 1. 算出 newLevel
    // 2. 比较 newLevel > currentLevel (playerLevel.value)
    // 3. 如果是，触发，更新 playerLevel

    if (levelInfo.level > playerLevel.value) {
      // 只有在非初始化(totalXp > 0) 且 确实变化时
      // 启动时 _calculateTimeMetrics 会跑一次，此时 playerLevel是1，newLevel可能是10
      // 我们不希望启动 App 就弹窗。
      // 策略：如果是第一次计算（启动），只同步不弹窗。
      // 我们可以加一个 _isInitialized 标记。

      if (_isInitialized) {
        _levelUpEvent.value = levelInfo.level;
        // 为了避免 Stream 粘性问题，稍微延迟一下重置? 其实不用，Rxn 每次变都会触发
        // 但 Rxn 如果值一样(比如连续升到5级?) 不会。
        // 最好用 .trigger(v) 如果是 Rx对象。
        _levelUpEvent.refresh();
      }
    }

    playerLevel.value = levelInfo.level;
    playerTitle.value = levelInfo.title;
    levelProgress.value = levelInfo.progress;

    // 标记初始化完成
    if (!_isInitialized) _isInitialized = true;
  }

  bool _isInitialized = false;

  // 刷新时间块数据 (计算密集型，暂放在前端做)
  void _refreshTimeBlocks() {
    // 1. 准备数据
    final targetDate = selectedDate.value;
    final allQuests = _questService.quests; // 获取最新的任务列表

    // 2. 调用纯领域算法生成网格
    // 这行代码体现了业务逻辑与状态管理的分离
    final newBlocks = TimeDomain.generateDailyBlocks(targetDate, allQuests);

    // 3. 更新状态
    timeBlocks.assignAll(newBlocks);
  }
}
