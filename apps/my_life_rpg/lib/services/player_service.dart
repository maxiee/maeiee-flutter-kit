import 'package:get/get.dart';
import 'package:my_life_rpg/core/logic/level_logic.dart';
import 'package:my_life_rpg/core/logic/xp_strategy.dart';
import 'package:my_life_rpg/core/utils/logger.dart';
import 'package:my_life_rpg/models/quest.dart';
import 'package:my_life_rpg/services/quest_service.dart';

class PlayerService extends GetxService {
  final QuestService _questService = Get.find();

  // --- State ---
  final playerLevel = 1.obs;
  final playerTitle = "NOVICE".obs;
  final levelProgress = 0.0.obs;
  final totalXp = 0.obs;
  final dailyXp = 0.obs; // 今日产出

  // --- Events ---
  final _levelUpEvent = Rxn<int>();
  Stream<int?> get onLevelUp => _levelUpEvent.stream;

  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    // 监听任务数据变化，一旦任务变动（时间增加/完成），重新计算玩家状态
    ever(_questService.quests, (_) => refreshStats());

    // 初始计算
    refreshStats();
  }

  void refreshStats() {
    _calculateXpAndLevel();
  }

  void _calculateXpAndLevel() {
    int grandTotalXp = 0;
    int todayXp = 0;
    final now = DateTime.now();

    for (var q in _questService.quests) {
      // 1. 计算总 XP
      int questSeconds = q.totalDurationSeconds;

      // 处理正在进行中的 Session (实时反馈)
      for (var s in q.sessions) {
        if (s.endTime == null) {
          final currentDuration = now.difference(s.startTime).inSeconds;
          questSeconds += (currentDuration - s.durationSeconds);
        }

        // 2. 顺便计算今日 XP
        if (s.startTime.year == now.year &&
            s.startTime.month == now.month &&
            s.startTime.day == now.day) {
          // 注意：这里粗略计算，未处理跨天截断，MVP阶段足够
          // 如果是进行中，用 currentDuration，否则用 s.durationSeconds
          int sDuration = s.endTime == null
              ? now.difference(s.startTime).inSeconds
              : s.durationSeconds;
          todayXp += StandardXpStrategy.instance.calculateBase(sDuration);
        }
      }

      grandTotalXp += StandardXpStrategy.instance.calculateBase(questSeconds);

      // Bonus XP
      if (q.type == QuestType.mission && q.isCompleted) {
        grandTotalXp += StandardXpStrategy.instance.calculate(0, true);
        // 如果是今天完成的，todayXp 也要加 Bonus?
        // 暂时不加复杂判断，保持简单
      }
    }

    // 更新状态
    totalXp.value = grandTotalXp;
    dailyXp.value = todayXp;

    // 计算等级
    final levelInfo = LevelLogic.calculate(grandTotalXp);
    final newLevel = levelInfo.level;
    final oldLevel = playerLevel.value;

    playerLevel.value = newLevel;
    playerTitle.value = levelInfo.title;
    levelProgress.value = levelInfo.progress;

    // 升级检测
    if (_isInitialized && newLevel > oldLevel) {
      _levelUpEvent.value = newLevel;
      // 重置事件以免重复触发? Rxn 会自动处理流
      _levelUpEvent.refresh();
      LogService.i("LEVEL UP! $oldLevel -> $newLevel", tag: "PlayerService");
    }

    if (!_isInitialized) _isInitialized = true;
  }
}
