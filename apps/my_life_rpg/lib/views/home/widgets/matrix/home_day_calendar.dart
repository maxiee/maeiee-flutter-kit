import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kalender/kalender.dart';
import 'package:my_life_rpg/controllers/matrix_controller.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';

class HomeDayCalendar extends StatelessWidget {
  final MatrixController c = Get.find();

  HomeDayCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return RpgContainer(
      padding: EdgeInsets.zero, // 移除内边距，让日历撑满
      child: CalendarView<SessionData>(
        calendarController: c.calendarController,
        eventsController: c.eventsController,
        viewConfiguration: MultiDayViewConfiguration.singleDay(),

        // --- 核心交互 ---
        callbacks: CalendarCallbacks(
          onEventTapped: (event, renderBox) => c.onEventTapped(event),
          onEventCreate: (event) => c.onEventCreate(event),
          onEventCreated: c.onEventCreated,
          // 禁止修改已存在的事件（根据需求，通常 Session 是不可变的，除非删除）
          onEventChanged: c.onEventChanged,
        ),

        header: null,
        body: CalendarBody<SessionData>(
          multiDayTileComponents: TileComponents(
            tileBuilder: (calendarEvent, info) {
              return Container(
                color: AppColors.accentMain.withOpacity(0.2),
                child: Center(child: Text(calendarEvent.data!.task.title)),
              );
            },
          ),
        ),
      ),
    );
  }
}
