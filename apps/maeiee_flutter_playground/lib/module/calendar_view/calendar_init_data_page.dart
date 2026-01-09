import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

DateTime get _now => DateTime.now();

class CalendarInitDataPage extends StatefulWidget {
  const CalendarInitDataPage({super.key});

  @override
  State<CalendarInitDataPage> createState() => _CalendarInitDataPageState();
}

class _CalendarInitDataPageState extends State<CalendarInitDataPage> {
  static bool isInitDataLoaded = false;

  EventController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = CalendarControllerProvider.of(context).controller;

    // Initialize events only when controller is first accessed
    if (_controller != controller) {
      _controller = controller;

      final events = [
        CalendarEventData(
          date: _now,
          title: "Project meeting",
          description: "Today is project meeting.",
          startTime: DateTime(_now.year, _now.month, _now.day, 18, 30),
          endTime: DateTime(_now.year, _now.month, _now.day, 22),
        ),
        CalendarEventData(
          date: _now,
          title: "Project meeting2",
          description: "Today is project meeting.",
          startTime: DateTime(_now.year, _now.month, _now.day, 18, 30),
          endTime: DateTime(_now.year, _now.month, _now.day, 23),
        ),
        CalendarEventData(
          date: _now.subtract(Duration(days: 3)),
          recurrenceSettings: RecurrenceSettings.withCalculatedEndDate(
            startDate: _now.subtract(Duration(days: 3)),
          ),
          title: "Leetcode Contest",
          description: "Give leetcode contest",
        ),
        CalendarEventData(
          date: _now.subtract(Duration(days: 3)),
          recurrenceSettings: RecurrenceSettings.withCalculatedEndDate(
            startDate: _now.subtract(Duration(days: 3)),
            frequency: RepeatFrequency.daily,
            recurrenceEndOn: RecurrenceEnd.after,
            occurrences: 5,
          ),
          title: "Physics test prep",
          description: "Prepare for physics test",
        ),
        CalendarEventData(
          date: _now.add(Duration(days: 1)),
          startTime: DateTime(_now.year, _now.month, _now.day, 18),
          endTime: DateTime(_now.year, _now.month, _now.day, 19),
          recurrenceSettings: RecurrenceSettings(
            startDate: _now,
            endDate: _now.add(Duration(days: 5)),
            frequency: RepeatFrequency.daily,
            recurrenceEndOn: RecurrenceEnd.after,
            occurrences: 5,
          ),
          title: "Wedding anniversary",
          description: "Attend uncle's wedding anniversary.",
        ),
        CalendarEventData(
          date: _now,
          startTime: DateTime(_now.year, _now.month, _now.day, 14),
          endTime: DateTime(_now.year, _now.month, _now.day, 17),
          title: "Football Tournament",
          description: "Go to football tournament.",
        ),
        CalendarEventData(
          date: _now.add(Duration(days: 3)),
          startTime: DateTime(
            _now.add(Duration(days: 3)).year,
            _now.add(Duration(days: 3)).month,
            _now.add(Duration(days: 3)).day,
            10,
          ),
          endTime: DateTime(
            _now.add(Duration(days: 3)).year,
            _now.add(Duration(days: 3)).month,
            _now.add(Duration(days: 3)).day,
            14,
          ),
          title: "Sprint Meeting.",
          description: "Last day of project submission for last year.",
        ),
        CalendarEventData(
          date: _now.subtract(Duration(days: 2)),
          startTime: DateTime(
            _now.subtract(Duration(days: 2)).year,
            _now.subtract(Duration(days: 2)).month,
            _now.subtract(Duration(days: 2)).day,
            14,
          ),
          endTime: DateTime(
            _now.subtract(Duration(days: 2)).year,
            _now.subtract(Duration(days: 2)).month,
            _now.subtract(Duration(days: 2)).day,
            16,
          ),
          title: "Team Meeting",
          description: "Team Meeting",
        ),
        CalendarEventData(
          date: _now.subtract(Duration(days: 2)),
          startTime: DateTime(
            _now.subtract(Duration(days: 2)).year,
            _now.subtract(Duration(days: 2)).month,
            _now.subtract(Duration(days: 2)).day,
            10,
          ),
          endTime: DateTime(
            _now.subtract(Duration(days: 2)).year,
            _now.subtract(Duration(days: 2)).month,
            _now.subtract(Duration(days: 2)).day,
            12,
          ),
          title: "Chemistry Viva",
          description: "Today is Joe's birthday.",
        ),
      ];
      _controller!.addAll(events);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar Init Data Demo')),
      body: Center(
        child: Text(
          'Calendar initialized with sample events.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
