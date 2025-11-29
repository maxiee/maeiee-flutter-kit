// lib/controllers/session_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import 'package:my_life_rpg/views/session/session_summary_view.dart';
import '../models/quest.dart';

class SessionController extends GetxController
    with GetTickerProviderStateMixin {
  final QuestService _questService = Get.find();

  late Quest quest;
  // 新增：当前会话对象
  late QuestSession currentSession;

  // 计时器状态
  Timer? _timer;
  final durationSeconds = 0.obs;

  // 界面状态
  final textController = TextEditingController();
  final scrollController = ScrollController();

  // 展示用的混合日志列表 (历史 + 新增)
  final displayLogs = <QuestLog>[].obs;

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

    // 1. 创建当前会话对象
    currentSession = QuestSession(startTime: DateTime.now());
    quest.sessions.add(currentSession);

    // [修复点]：将 notifyUpdate 推迟到帧结束
    // 避免在 build 过程中触发其他 Widget 的 rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _questService.notifyUpdate();
    });

    // 2. 加载历史日志
    displayLogs.addAll(quest.allLogs);

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
      _updateDuration();
    });
  }

  // [修改点]：基于物理时间的计算
  void _updateDuration() {
    final now = DateTime.now();
    // 强制转换为秒
    durationSeconds.value = now.difference(currentSession.startTime).inSeconds;
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

    // 1. 加到当前 session
    currentSession.logs.add(newLog);

    // 2. 加到展示列表 (UI 更新)
    displayLogs.add(newLog); // 应该插到最前面还是最后面？看你的 ListView 是正序还是倒序
    // 假设 allLogs 是倒序的（最新的在前面），那么新 Log 应该 insert(0, newLog)
    // 但如果 SessionView 是从上往下流动的（最新的在下面），那么 add 就行。
    // 我们之前的 SessionView 是正序的 (add)，所以这里用 add。

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

  // 结束任务 (结算逻辑)
  void endSession() async {
    // 1. 停止计时
    stopTimer();

    // 2. 预计算最终数据 (Snapshot)
    // 此时数据已经写入了 currentSession (因为是对象引用)
    // 但我们需要确保状态是最新的，以便 UI 显示
    final now = DateTime.now();
    currentSession.endTime = now;
    final duration = now.difference(currentSession.startTime).inSeconds;
    currentSession.durationSeconds = duration;

    // 简单的 XP 计算公式 (1分钟 = 1XP)
    final xpEarned = (duration / 60).floor();
    final logsCount = currentSession.logs.length;
    final isDaemon = quest.type == QuestType.daemon;

    // 3. 通知全局更新 (让 Matrix 和 HUD 知道这块时间被占用了)
    _questService.notifyUpdate();

    // 4. 弹出结算模态窗 (等待用户决策)
    final result = await Get.generalDialog(
      pageBuilder: (ctx, anim1, anim2) {
        return SessionSummaryView(
          durationSeconds: duration,
          logsCount: logsCount,
          xpEarned: xpEarned,
          isDaemon: isDaemon,
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
      barrierColor: Colors.black, // 纯黑背景沉浸感
      barrierDismissible: false, // 禁止点击背景关闭，强制选择
    );

    // 5. 解析用户决策结果
    // 默认为 null (理论上不会，但防防御性编程) -> 视为保存但不完成
    bool shouldSave = true;
    bool shouldComplete = false;

    if (result != null && result is Map) {
      shouldSave = result['save'] ?? true;
      shouldComplete = result['complete'] ?? false;
    }

    // 6. 执行决策
    if (shouldSave) {
      // A. 保存模式
      // Session 已经在列表中了，不需要额外 add

      // 如果用户标记了完成/循环
      if (shouldComplete) {
        // 调用 Service 切换完成状态 (这会处理 Daemon 的 CD 重置)
        _questService.toggleQuestCompletion(quest.id);
      }

      // 可选：在这里弹出 SnackBar 提示保存成功
      // 但因为要退回首页，最好由首页来弹，或者依赖 SessionSummaryView 的反馈
    } else {
      // B. 丢弃模式 (DISCARD)
      // 从 Quest 的 Session 列表中移除当前的 session 对象
      quest.sessions.remove(currentSession);

      // 强制刷新 Service，通知 TimeService 移除矩阵上的色块
      _questService.notifyUpdate();
    }

    // 7. 退出 Session 页面
    // 延迟极短时间，避免弹窗关闭动画和页面退出动画冲突
    Future.delayed(const Duration(milliseconds: 50), () {
      // 返回 duration 给 MissionCard 做简单的 SnackBar 反馈 (如果是 Save)
      Get.back(result: shouldSave ? duration : null);
    });
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
