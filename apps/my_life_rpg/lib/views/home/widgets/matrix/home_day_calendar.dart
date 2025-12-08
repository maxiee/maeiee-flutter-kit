import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kalender/kalender.dart';
import 'package:my_life_rpg/controllers/matrix_controller.dart';
import 'package:my_life_rpg/core/core.dart';

class HomeDayCalendar extends StatelessWidget {
  final MatrixController c = Get.find();

  HomeDayCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return RpgContainer(
      child: CalendarView(
        calendarController: c.calendarController,
        eventsController: c.eventsController,
        viewConfiguration: MultiDayViewConfiguration.singleDay(),
        callbacks: CalendarCallbacks(
          onEventTapped: (event, renderBox) {},
          onEventCreate: (event) {},
          onEventCreated: (event) {},
        ),
        header: null,
        body: CalendarBody(),
      ),
    );
  }
}
