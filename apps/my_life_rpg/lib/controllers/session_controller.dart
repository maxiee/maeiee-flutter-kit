// lib/controllers/session_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_life_rpg/services/task_service.dart';
import 'package:my_life_rpg/views/session/session_summary_view.dart';
import '../models/task.dart';

class SessionController extends GetxController
    with GetTickerProviderStateMixin {
  final TaskService _questService = Get.find();

  // 转为 Rx 变量，以便 UI 能够监听任务本身的变化 (如子任务状态)
  late Rx<Task> questRx;
  Task get quest => questRx.value;

  // 新增：当前会话对象
  late FocusSession currentSession;

  // 计时器状态
  Timer? _timer;
  final durationSeconds = 0.obs;
  final effectiveSeconds = 0.obs; // [新增] 有效专注时间
  final isPaused = false.obs; // [新增] 暂停状态

  // 暂停辅助变量
  DateTime? _pauseStartTime;

  // 界面状态
  final textController = TextEditingController();
  final scrollController = ScrollController();
  final displayLogs = <TaskLog>[].obs; // 展示用的混合日志列表 (历史 + 新增)

  // 动画控制器 (用于呼吸效果)
  late AnimationController pulseController;
  late Animation<double> pulseAnimation;

  @override
  void onInit() {
    super.onInit();

    if (Get.arguments is Task) {
      // [修改] 将传入的任务包装为 Rx，并监听 Service 的更新
      // 这样当我们在 Service 里更新了数据库，这里的 UI 也会刷新
      final originTask = Get.arguments as Task;
      questRx = originTask.obs;

      // 监听全局任务列表，如果当前任务在外部被修改，同步更新这里
      // (虽然 Session 期间极少发生外部修改，但保持一致性是好的)
      ever(_questService.tasks, (List<Task> tasks) {
        final fresh = tasks.firstWhereOrNull((t) => t.id == originTask.id);
        if (fresh != null) {
          questRx.value = fresh;
        }
      });
    } else {
      questRx = Task(id: 'mock', title: '调试任务', type: TaskType.todo).obs;
    }

    // 1. 创建当前会话对象
    currentSession = FocusSession(startTime: DateTime.now());
    // 注意：这里的 quest 是 Rx 的 value，修改它的 list 需要小心引用问题
    // 简单起见，我们直接操作 quest 对象
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
    // 物理时长 = 当前 - 开始
    final total = now.difference(currentSession.startTime).inSeconds;

    // 有效时长 = 物理时长 - 累积暂停
    // 注意：如果是 Resume 瞬间，pausedSeconds 已经更新了
    final effective = total - currentSession.pausedSeconds;

    durationSeconds.value = total;
    effectiveSeconds.value = effective > 0 ? effective : 0;

    // 实时同步给 Model (为了 Crash 安全，虽然有点频繁，但内存操作没事)
    currentSession.durationSeconds = total;
  }

  void stopTimer() {
    _timer?.cancel();
  }

  // 动作：切换暂停
  void togglePause() {
    if (isPaused.value) {
      _resume();
    } else {
      _pause();
    }
  }

  void _pause() {
    isPaused.value = true;
    _pauseStartTime = DateTime.now();

    // 动画暂停，营造冻结感
    pulseController.stop();

    // 自动记录一条 Log
    addLog(content: "--- TACTICAL PAUSE ---", type: LogType.rest);
  }

  void _resume() {
    if (_pauseStartTime != null) {
      final pauseDuration = DateTime.now()
          .difference(_pauseStartTime!)
          .inSeconds;
      currentSession.pausedSeconds += pauseDuration;
      _pauseStartTime = null;
    }

    isPaused.value = false;
    pulseController.repeat(reverse: true);

    // 刷新一下时间，避免跳变
    _updateDuration();
  }

  // 核心操作：添加日志
  void addLog({String? content, LogType type = LogType.normal}) {
    final text = content ?? textController.text.trim();
    if (text.isEmpty) return;

    final newLog = TaskLog(
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

  // 切换子任务状态
  void toggleSubTask(int index) {
    final subList = List<SubTask>.from(quest.checklist);
    final sub = subList[index];

    // 1. 切换状态
    sub.isCompleted = !sub.isCompleted;

    // 2. 自动记录日志 (仅当完成时)
    if (sub.isCompleted) {
      addLog(
        content: "[CHECKPOINT] 完成节点: ${sub.title}",
        type: LogType.milestone,
      );
    }

    // 3. 更新 Service (持久化)
    // 注意：updateTask 会触发 Service 的 refresh，进而触发上面的 ever 回调
    // 从而更新 questRx.value，触发 UI 重绘
    _questService.updateTask(quest.id, checklist: subList);
  }

  // 结束任务 (结算逻辑)
  void endSession() async {
    // 1. 停止计时
    stopTimer();

    // 如果是在暂停状态结束的，需要把最后这一段暂停时间加上
    if (isPaused.value && _pauseStartTime != null) {
      final pauseDuration = DateTime.now()
          .difference(_pauseStartTime!)
          .inSeconds;
      currentSession.pausedSeconds += pauseDuration;
    }

    // 2. 预计算最终数据 (Snapshot)
    // 此时数据已经写入了 currentSession (因为是对象引用)
    // 但我们需要确保状态是最新的，以便 UI 显示
    final now = DateTime.now();
    currentSession.endTime = now;

    // 最终计算
    final totalDuration = now.difference(currentSession.startTime).inSeconds;
    currentSession.durationSeconds = totalDuration;

    // [关键修正] XP 计算应该基于【有效时长】，而不是物理时长
    final effective = totalDuration - currentSession.pausedSeconds;

    final logsCount = currentSession.logs.length;
    final isDaemon = quest.type == TaskType.routine;

    // 3. 通知全局更新 (让 Matrix 和 HUD 知道这块时间被占用了)
    _questService.notifyUpdate();

    // 4. 弹出结算模态窗 (等待用户决策)
    // 弹出新的 Report Dialog
    final result = await Get.generalDialog(
      pageBuilder: (ctx, _, _) {
        return SessionSummaryView(
          durationSeconds: effective,
          logsCount: logsCount,
          // xpEarned: xpEarned, // 删除参数
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
        _questService.toggleTaskCompletion(quest.id);
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
      Get.back(result: shouldSave ? effective : null);
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
