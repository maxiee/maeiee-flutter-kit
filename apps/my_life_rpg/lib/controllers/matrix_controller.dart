import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:calendar_view/calendar_view.dart'; // [New Import]
import 'package:my_life_rpg/models/task.dart';
import 'package:my_life_rpg/services/task_service.dart';
import 'package:my_life_rpg/services/time_service.dart';
import 'package:rpg_cyber_ui/theme/app_colors.dart';
import 'package:my_life_rpg/views/home/widgets/matrix/session_inspector.dart';
import 'package:my_life_rpg/views/home/widgets/matrix/time_allocation_dialog.dart';

/// 封装事件数据上下文
class SessionData {
  final Task task;
  final FocusSession session;
  SessionData(this.task, this.session);
}

class MatrixController extends GetxController {
  final TaskService _questService = Get.find();
  final TimeService _timeService = Get.find();

  // [New] CalendarView 的核心控制器
  final EventController<SessionData> eventController = EventController();

  // 绑定到 UI 的 GlobalKey，用于控制视图跳转
  final GlobalKey<DayViewState> dayViewKey = GlobalKey<DayViewState>();

  @override
  void onInit() {
    super.onInit();
    _syncEvents();

    // 监听任务变化 -> 更新日历数据
    ever(_questService.tasks, (_) => _syncEvents());

    // 监听日期变化 -> 跳转视图
    ever(_timeService.selectedDate, (date) {
      // 这里的 currentState 可能为空，如果 View 还没构建
      dayViewKey.currentState?.animateToDate(date);
    });
  }

  /// [核心逻辑] 数据适配器：Domain Model -> Calendar View Model
  void _syncEvents() {
    final List<CalendarEventData<SessionData>> events = [];

    for (var task in _questService.tasks) {
      for (var session in task.sessions) {
        // 处理进行中任务：暂时以当前时间为结束，或者 +15分钟
        final endTime =
            session.endTime ?? DateTime.now().add(const Duration(minutes: 15));

        // 确保时间有效
        if (endTime.isBefore(session.startTime)) continue;

        // 获取颜色 (根据任务类型或 Project)
        Color color = AppColors.accentMain;
        if (task.type == TaskType.routine) color = AppColors.accentSystem;
        // 如果需要更细致的 Project 颜色，可以从 task.projectId 查找 Project 对象，这里暂略保持 KISS

        events.add(
          CalendarEventData(
            date: session.startTime, // 必须是日期部分，库会自动处理
            startTime: session.startTime,
            endTime: endTime,
            title: task.title,
            description: task.projectName ?? "NO SECTOR",
            color: color,
            event: SessionData(task, session), // 携带原始数据
          ),
        );
      }
    }

    // 全量替换数据
    // calendar_view 没有直接的 clearAll+addAll 原子操作，但 removeWhere + addAll 可行
    // 或者直接新建 controller (不推荐)。2.0.0 版本 EventController 有 clear() 方法吗？
    // 根据文档，2.0.0 增加了 clear()。
    eventController.clear();
    eventController.addAll(events);
  }

  /// [交互] 点击事件 -> 查看详情
  void onEventTapped(CalendarEventData<SessionData> event) {
    final data = event.event;
    if (data == null) return;

    Get.dialog(
      SessionInspector(quest: data.task, session: data.session),
      barrierColor: Colors.black.withOpacity(0.8),
    );
  }

  /// [交互] 长按空白处 -> 新建分配
  void onSlotLongPressed(DateTime date) async {
    // date 包含了点击的具体时间点
    final initialStart = date;
    final initialEnd = date.add(const Duration(minutes: 30)); // 默认半小时

    final result = await Get.dialog(
      TimeAllocationDialog(
        startTime: initialStart,
        endTime: initialEnd,
        questService: _questService,
      ),
      barrierColor: Colors.black.withOpacity(0.8),
    );

    // Dialog 内部处理了数据保存，这里只需要刷新（ever 监听会自动处理）
    if (result != null) {
      // 成功提示
    }
  }
}
