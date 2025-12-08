import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kalender/kalender.dart';
import 'package:my_life_rpg/core/theme/app_colors.dart';
import 'package:my_life_rpg/services/task_service.dart';
import 'package:my_life_rpg/services/time_service.dart';
import 'package:my_life_rpg/views/home/widgets/matrix/session_inspector.dart';
import 'package:my_life_rpg/views/home/widgets/matrix/time_allocation_dialog.dart';
import '../models/task.dart';

/// 封装事件数据，方便在 UI 层获取上下文
class SessionData {
  final Task task;
  final FocusSession session;
  SessionData(this.task, this.session);
}

class MatrixController extends GetxController {
  // 依赖注入：直接获取 Service
  final TaskService _questService = Get.find();
  final TimeService _timeService = Get.find();

  final eventsController = DefaultEventsController<SessionData>();
  final calendarController = CalendarController<SessionData>();

  @override
  void onInit() {
    super.onInit();
    // 初始同步
    _syncEvents();
    // 监听任务变化，实时刷新日历
    ever(_questService.tasks, (_) => _syncEvents());
    // 监听日期变化，跳转日历视图
    ever(_timeService.selectedDate, (date) {
      calendarController.animateToDate(date);
    });
  }

  @override
  void onClose() {
    super.onClose();
    eventsController.dispose();
    calendarController.dispose();
  }

  /// [核心逻辑] 将领域模型的 Sessions 转换为日历 Events
  void _syncEvents() {
    final List<CalendarEvent<SessionData>> events = [];

    for (var task in _questService.tasks) {
      for (var session in task.sessions) {
        // 处理正在进行中的 Session (End == null)
        // 为了显示，暂时将其结束时间设为当前时间，或者设为未来一小段时间
        final endTime = session.endTime ?? DateTime.now();
        // 防止无效时间段 (Start >= End)
        if (!endTime.isAfter(session.startTime)) continue;

        // 如果有关联项目，尝试获取项目颜色 (这里简化处理，实际可从 Project Repo 获取)
        // 为了性能，我们暂且只用 Type 区分，或者在 event tile builder 里再查 Project

        events.add(
          CalendarEvent(
            dateTimeRange: DateTimeRange(
              start: session.startTime,
              end: endTime,
            ),
            data: SessionData(task, session),
          ),
        );
      }
    }

    // 替换所有事件
    // 注意：kalender 的 addEvents 可能会追加，我们需要先清空或使用 assign
    // 目前 kalender 没有直接 clearAll 的简单方法，通常是重新构建 Controller 或 diff
    // 假设 eventsController.removeWhere((e) => true) 可用
    eventsController.removeWhere((_, _) => true);
    eventsController.addEvents(events);
  }

  /// [交互] 点击事件 -> 查看详情
  void onEventTapped(CalendarEvent<SessionData> event) {
    final data = event.data;
    if (data == null) return;

    Get.dialog(
      SessionInspector(quest: data.task, session: data.session),
      barrierColor: Colors.black54,
    );
  }

  /// [回调 2] onEventCreate (同步): 允许 UI 创建占位符
  CalendarEvent<SessionData>? onEventCreate(CalendarEvent<SessionData> event) {
    // 返回 event 告诉日历：“允许在这里渲染一个临时的块”
    // 我们可以在这里给它一个临时的颜色，表示“正在输入”
    return event.copyWith();
  }

  /// [回调 3] onEventCreated (异步): 真正的业务逻辑
  Future<void> onEventCreated(CalendarEvent<SessionData> event) async {
    final start = event.dateTimeRange.start;
    final end = event.dateTimeRange.end;

    // 格式化时间
    final timeStr =
        "${_fmt(start.hour)}:${_fmt(start.minute)} - ${_fmt(end.hour)}:${_fmt(end.minute)}";

    // 1. 弹出对话框
    final result = await Get.dialog(
      TimeAllocationDialog(
        timeRangeText: timeStr,
        startTime: start,
        endTime: end,
        questService: _questService,
      ),
      barrierColor: Colors.black54,
    );

    // 2. 处理结果
    if (result != null && result is Map) {
      final isNew = result['isNew'] as bool;
      String targetQuestId;

      if (isNew) {
        final title = result['title'] as String;
        final newQ = _questService.addNewTask(
          title: title,
          type: TaskType.todo,
        );
        targetQuestId = newQ.id;
      } else {
        targetQuestId = result['id'] as String;
      }

      final allocateResult = _questService.manualAllocate(
        targetQuestId,
        start,
        end,
      );

      if (!allocateResult.isSuccess) {
        Get.snackbar(
          "ACCESS DENIED",
          "Time slot collision detected.",
          backgroundColor: AppColors.bgPanel,
          colorText: AppColors.accentDanger,
        );
        // 失败：移除占位符
        eventsController.removeEvent(event);
      } else {
        // 成功：
        // 不需要手动把 event 变成永久的，
        // 因为 manualAllocate 会触发 ever(_questService.tasks) -> _syncEvents
        // _syncEvents 会清空所有事件（包括这个占位符）并重新加载真实的 Session 数据。
      }
    } else {
      // 用户取消：移除占位符
      eventsController.removeEvent(event);
    }
  }

  /// [回调 4] onEventChanged: 禁止/允许修改
  // 如果你想禁止拖拽修改已有的 Session，这里什么都不做或者恢复原状
  // 如果允许修改时间，需要调用 Service 更新 Session
  Future<void> onEventChanged(
    CalendarEvent<SessionData> initial,
    CalendarEvent<SessionData> updated,
  ) async {
    // 暂时不支持直接在日历上调整已保存 Session 的大小（逻辑较复杂，涉及 TaskService 更新）
    // 强制回滚：移除修改后的，加回原来的 (或者重新 sync)
    // 简单做法：直接触发一次 sync 覆盖掉 UI 的修改
    _syncEvents();

    // 提示
    Get.snackbar(
      "SYSTEM LOCKED",
      "Modification via timeline is disabled. Use Inspector.",
    );
  }

  String _fmt(int n) => n.toString().padLeft(2, '0');
}
