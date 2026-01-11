import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_life_rpg/controllers/matrix_controller.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';

// --- 1. 战术周视图 (Tactical Week Protocol) ---
class WeekViewPage extends StatelessWidget {
  const WeekViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MatrixController c = Get.find();

    return Scaffold(
      backgroundColor: AppColors.bgDarkest,
      appBar: _buildAppBar("TACTICAL WEEK VIEW"),
      body: Theme(
        // [Hack] 通过 Theme 覆盖垂直分割线的颜色 (通常取自 dividerColor)
        data: Theme.of(
          context,
        ).copyWith(dividerColor: Colors.white.withOpacity(0.05)),
        child: WeekView<SessionData>(
          controller: c.eventController,
          backgroundColor: Colors.transparent,

          // [关键修复 1] 顶部导航栏样式重写
          headerStyle: const HeaderStyle(
            decoration: BoxDecoration(
              color: AppColors.bgPanel, // 深色背景
              border: Border(bottom: BorderSide(color: AppColors.borderDim)),
            ),
            headerTextStyle: TextStyle(
              color: AppColors.accentMain,
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
            leftIconConfig: IconDataConfig(color: AppColors.textDim, size: 20),
            rightIconConfig: IconDataConfig(color: AppColors.textDim, size: 20),
          ),

          // [关键修复 2] 星期栏背景透明
          weekTitleBackgroundColor: Colors.transparent,
          weekTitleHeight: 50,

          // [关键修复 3] 红色激光指针 (同步 DayView)
          liveTimeIndicatorSettings: const LiveTimeIndicatorSettings(
            color: AppColors.accentDanger,
            height: 1,
            showBullet: false,
            showTime: true,
            showTimeBackgroundView: false,
            offset: 0,
          ),

          // 基础布局配置
          heightPerMinute: 1.0,
          showLiveTimeLineInAllDays: true,
          timeLineWidth: 50,
          showVerticalLines: true, // 开启垂直线 (颜色由上方 Theme.dividerColor 控制)
          timeLineOffset: 4,

          // 网格线样式
          hourIndicatorSettings: HourIndicatorSettings(
            color: Colors.white.withOpacity(0.05),
            lineStyle: LineStyle.dashed,
          ),

          // 左侧时间轴
          timeLineBuilder: (date) => Transform.translate(
            offset: const Offset(0, -6),
            child: Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Text(
                "${date.hour.toString().padLeft(2, '0')}:00",
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.textDim.withOpacity(0.5),
                  fontFamily: 'Courier',
                  fontSize: 10,
                ),
              ),
            ),
          ),

          // 顶部星期栏 (Week Header)
          weekDayBuilder: (date) {
            final isToday =
                date.day == DateTime.now().day &&
                date.month == DateTime.now().month &&
                date.year == DateTime.now().year;
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday ? AppColors.accentMain.withOpacity(0.1) : null,
                // 只保留右侧分割线，底部由 Header 统一控制
                border: Border(
                  right: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isToday ? AppColors.accentMain : Colors.grey,
                      fontFamily: 'Courier',
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: isToday ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            );
          },

          // 事件块渲染
          eventTileBuilder: (date, events, boundary, start, end) {
            final event = events.first;
            return Container(
              decoration: BoxDecoration(
                color: event.color.withOpacity(0.15),
                border: Border(
                  left: BorderSide(color: event.color, width: 2),
                  top: BorderSide(
                    color: event.color.withOpacity(0.3),
                    width: 0.5,
                  ),
                  bottom: BorderSide(
                    color: event.color.withOpacity(0.3),
                    width: 0.5,
                  ),
                  right: BorderSide(
                    color: event.color.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                borderRadius: BorderRadius.circular(1),
              ),
              padding: const EdgeInsets.all(2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },

          // [FIXED] 显式类型转换，防止 BuildContext 报错
          onEventTap: (events, date) {
            c.onEventTapped(events.first as CalendarEventData<SessionData>);
          },
        ),
      ),
    );
  }
}

// --- 2. 战略月视图 (保持之前的修复) ---
class MonthViewPage extends StatelessWidget {
  const MonthViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MatrixController c = Get.find();

    return Scaffold(
      backgroundColor: AppColors.bgDarkest,
      appBar: _buildAppBar("STRATEGIC MONTH OVERVIEW"),
      body: MonthView<SessionData>(
        controller: c.eventController,
        monthViewBuilders: MonthViewBuilders(
          headerBuilder: MonthHeader.hidden,
          onEventTap: (event, date) {
            c.onEventTapped(event as CalendarEventData<SessionData>);
          },
          cellBuilder: (date, events, isToday, isInMonth, hideDaysNotInMonth) {
            if (!isInMonth) return const SizedBox.shrink();

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                color: isToday ? AppColors.accentMain.withOpacity(0.05) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      date.day.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: isToday ? AppColors.accentMain : Colors.grey,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                  if (events.isNotEmpty)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ...events
                                .take(3)
                                .map(
                                  (e) => Container(
                                    height: 3,
                                    margin: const EdgeInsets.only(bottom: 2),
                                    decoration: BoxDecoration(
                                      color: e.color,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                ),
                            if (events.length > 3)
                              Container(
                                height: 3,
                                width: 3,
                                decoration: const BoxDecoration(
                                  color: Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// 辅助方法
PreferredSizeWidget _buildAppBar(String title) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    title: Text(
      title,
      style: const TextStyle(
        fontFamily: 'Courier',
        fontWeight: FontWeight.bold,
        color: AppColors.accentMain,
        letterSpacing: 2,
      ),
    ),
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.accentMain),
      onPressed: () => Get.back(),
    ),
  );
}
