import 'package:flutter/material.dart';
import 'package:maeiee_flutter_playground/module/calendar_view/multi_day/multi_day_view_widget.dart';

class MultiDayViewDemo extends StatefulWidget {
  const MultiDayViewDemo({super.key});

  @override
  _MultiDayViewDemoState createState() => _MultiDayViewDemoState();
}

class _MultiDayViewDemoState extends State<MultiDayViewDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(
        // child: Icon(Icons.add, color: context.appColors.onPrimary),
        elevation: 8,
        onPressed: () {},
        // onPressed: () => context.pushRoute(CreateEventPage()),
      ),
      body: MultiDayViewWidget(),
    );
  }
}
