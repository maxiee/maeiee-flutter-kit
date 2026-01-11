import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_life_rpg/controllers/matrix_controller.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';

// --- 1. 战术周视图 (WeekView 保持不变，因为 API 似乎没有这么大的变动，或者稍后检查) ---
class WeekViewPage extends StatelessWidget {
  const WeekViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MatrixController c = Get.find();

    return Scaffold(
      backgroundColor: AppColors.bgDarkest,
      appBar: _buildAppBar("TACTICAL WEEK VIEW"),
      body: WeekView<SessionData>(
        controller: c.eventController,
        backgroundColor: Colors.transparent,
        heightPerMinute: 1.0,
        showLiveTimeLineInAllDays: true,
        timeLineWidth: 50,
        showVerticalLines: true,
        timeLineOffset: 4,
        hourIndicatorSettings: HourIndicatorSettings(
          color: Colors.white.withOpacity(0.05),
          lineStyle: LineStyle.dashed,
        ),
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
        weekDayBuilder: (date) {
          final isToday =
              date.day == DateTime.now().day &&
              date.month == DateTime.now().month;
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isToday ? AppColors.accentMain.withOpacity(0.1) : null,
              border: const Border(bottom: BorderSide(color: Colors.white12)),
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
                  ),
                ),
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    color: isToday ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
        eventTileBuilder: (date, events, boundary, start, end) {
          final event = events.first;
          return Container(
            decoration: BoxDecoration(
              color: event.color.withOpacity(0.2),
              border: Border(left: BorderSide(color: event.color, width: 2)),
              borderRadius: BorderRadius.circular(2),
            ),
            padding: const EdgeInsets.all(2),
            child: Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontFamily: 'Courier',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
        onEventTap: (events, date) => c.onEventTapped(events.first),
      ),
    );
  }
}

// --- 2. 战略月视图 (修复参数错误) ---
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
        // [FIXED] 使用 monthViewBuilders 封装回调
        monthViewBuilders: MonthViewBuilders(
          // 隐藏 Header
          headerBuilder: MonthHeader.hidden,

          // 点击事件
          onEventTap: (event, date) =>
              c.onEventTapped(event as CalendarEventData<SessionData>),

          // 单元格渲染
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
                  // 日期数字
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      date.day.toString(),
                      style: TextStyle(
                        color: isToday ? AppColors.accentMain : Colors.grey,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                  // 指示器
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

// 辅助方法 (保持不变)
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
