import 'dart:async';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/domain/time_domain.dart';
import 'package:my_life_rpg/core/utils/logger.dart';
import 'package:my_life_rpg/models/block_state.dart';
import 'task_service.dart';

class TimeService extends GetxService {
  final TaskService _questService = Get.find(); // 依赖注入

  // 状态
  final selectedDate = DateTime.now().obs;
  final timeBlocks = <BlockState>[].obs;

  // 指标
  final timeRemainingStr = ''.obs; // 改名：不再叫 timeToSleep
  final effectiveRatio = 0.0.obs;
  final entropyRatio = 0.0.obs;
  final futureRatio = 1.0.obs;

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

  final currentTime = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();

    // 初始化空数据，防止 UI 渲染越界
    timeBlocks.value = List.generate(96, (_) => BlockState.empty());

    // 监听：任务列表变化 或 日期选择变化 都要刷新
    ever(_questService.tasks, (_) => refreshMatrix());

    _heartbeat = Timer.periodic(const Duration(minutes: 1), (_) {
      // 1. 更新时钟信号
      currentTime.value = DateTime.now();
      // 2. 重新计算指标
      _calculateTimeMetrics();
    });
    _calculateTimeMetrics();
  }

  @override
  void onReady() {
    super.onReady();
    // 此时所有 Service 都已初始化完毕，Repo 数据肯定都在了
    // 强制刷新一次，确保视图同步
    LogService.d(
      "TimeService Ready - Force Refreshing Matrix",
      tag: "TimeService",
    );
    refreshMatrix();
  }

  void changeDate(DateTime date) {
    selectedDate.value = date;
    // _refreshTimeBlocks 会被 ever 触发，但 calculateTimeMetrics 需要手动触发一下以防万一
    _refreshTimeBlocks();
  }

  void refreshMatrix() {
    _calculateTimeMetrics();
    _refreshTimeBlocks();
  }

  // 自然日核心算法
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

    final allSessions = _questService.tasks.expand((q) => q.sessions).toList();

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
  }

  // 刷新时间块数据 (计算密集型，暂放在前端做)
  void _refreshTimeBlocks() {
    // 1. 准备数据
    final targetDate = selectedDate.value;
    final allQuests = _questService.tasks; // 获取最新的任务列表

    // 2. 调用纯领域算法生成网格
    // 这行代码体现了业务逻辑与状态管理的分离
    final newBlocks = TimeDomain.generateDailyBlocks(targetDate, allQuests);

    // 3. 更新状态
    timeBlocks.assignAll(newBlocks);

    LogService.d(
      "Time matrix refreshed for ${selectedDate.value}",
      tag: "TimeService",
    );
  }
}
