import 'package:flutter/material.dart';
import 'package:maeiee_flutter_playground/module/calendar_view/month/day_view_widget.dart';

class DayViewPageDemo extends StatefulWidget {
  const DayViewPageDemo({super.key});

  @override
  _DayViewPageDemoState createState() => _DayViewPageDemoState();
}

class _DayViewPageDemoState extends State<DayViewPageDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(
        elevation: 8,
        onPressed: () {},
        // onPressed: () => context.pushRoute(CreateEventPage()),
      ),
      body: DayViewWidget(),
    );
  }
}
