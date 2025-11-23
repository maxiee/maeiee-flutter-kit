// lib/controllers/session_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/quest.dart';
// 确保引入了 game_controller，如果你还没用到它可以暂时注释掉，
// 但为了回写数据（endSession），后续肯定需要它。
import 'game_controller.dart';

class SessionController extends GetxController
    with GetTickerProviderStateMixin {
  // 引用 GameController 用于更新数据
  final GameController _gameController = Get.find();

  late Quest quest;

  // 计时器状态
  Timer? _timer;
  final durationSeconds = 0.obs;

  // 界面状态
  final textController = TextEditingController();
  final scrollController = ScrollController();

  // 临时日志列表 (包含历史日志 + 本次新增日志)
  final currentLogs = <QuestLog>[].obs;

  // 动画控制器 (用于呼吸效果)
  late AnimationController pulseController;
  late Animation<double> pulseAnimation;

  @override
  void onInit() {
    super.onInit();

    // 1. 获取传递过来的 Quest 对象
    if (Get.arguments is Quest) {
      quest = Get.arguments as Quest;
    } else {
      // 防止空参数崩溃 (调试用)
      quest = Quest(id: 'mock', title: '调试任务', type: QuestType.mission);
    }

    // 2. 加载历史日志
    currentLogs.addAll(quest.logs);

    // 3. 初始化呼吸灯动画 (2秒一个周期)
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    pulseAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );
    pulseController.repeat(reverse: true);

    // 4. 启动计时
    startTimer();

    // 自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      durationSeconds.value++;
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }

  // 核心操作：添加日志
  void addLog({String? content, LogType type = LogType.normal}) {
    final text = content ?? textController.text.trim();
    if (text.isEmpty) return;

    final newLog = QuestLog(
      createdAt: DateTime.now(),
      content: text,
      type: type,
    );

    currentLogs.add(newLog);

    // 如果是手动输入的(content为null)，清空输入框
    if (content == null) {
      textController.clear();
      // 保持焦点方便继续输入，或者收起键盘看个人喜好，这里保持焦点
    }

    _scrollToBottom();
  }

  // 宏指令逻辑
  void triggerMacro(String label, LogType type, String prefix) {
    if (type == LogType.rest) {
      // 休息类型直接发送，不走输入框
      addLog(content: "[休息] 暂停了一会儿...", type: type);
    } else {
      // 其他类型：填入前缀，等待用户输入
      textController.text = "$prefix ";
      // 光标移到最后
      textController.selection = TextSelection.fromPosition(
        TextPosition(offset: textController.text.length),
      );
      // 这里的 context 比较难获取，通常 TextField 设置 autofocus 或者使用 FocusNode
      // 为了 MVP，我们假设用户点了宏之后键盘会自动弹起（因为 TextField 获得焦点）
    }
  }

  // 辅助：滚动到底部
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 结束任务 (结算)
  void endSession() {
    stopTimer();

    // --- 数据回写逻辑 ---
    // 1. 更新 Quest 对象的内存数据
    quest.totalDurationSeconds += durationSeconds.value;
    quest.logs.clear();
    quest.logs.addAll(currentLogs);

    // 2. 如果是 Daemon，更新 lastDoneAt
    if (quest.type == QuestType.daemon) {
      // quest.lastDoneAt = DateTime.now(); // Quest 如果是 final 字段需要 copyWith 或者特殊处理
      // 假设 Quest 是不可变的，我们需要在 GameController 里替换它
      // 这里暂时只做简单的内存 Log 更新演示
    }

    // 3. 通知 GameController 刷新界面 (XP 计算等)
    // 这一步很重要，否则首页的 XP 和 Time Spectrum 不会变
    _gameController.quests.refresh();
    _gameController.update(); // 触发 update

    // result: true 表示“正常结算退出”，而不是直接按返回键
    Get.back(result: durationSeconds.value);
  }

  String formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String formatTime(DateTime dt) {
    return DateFormat('MM-dd HH:mm').format(dt);
  }

  @override
  void onClose() {
    stopTimer();
    pulseController.dispose();
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
