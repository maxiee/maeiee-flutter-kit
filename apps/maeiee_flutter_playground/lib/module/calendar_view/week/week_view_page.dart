import 'package:flutter/material.dart';
import 'package:maeiee_flutter_playground/module/calendar_view/week/week_view_widget.dart';

class WeekViewDemo extends StatefulWidget {
  const WeekViewDemo({super.key});

  @override
  _WeekViewDemoState createState() => _WeekViewDemoState();
}

class _WeekViewDemoState extends State<WeekViewDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(
        elevation: 8,
        onPressed: () {},
        // onPressed: () => context.pushRoute(CreateEventPage()),
      ),
      body: WeekViewWidget(),
    );
  }
}
