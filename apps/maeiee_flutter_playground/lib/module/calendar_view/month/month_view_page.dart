import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:maeiee_flutter_playground/module/calendar_view/month/month_view_widget.dart';

class MonthViewPageDemo extends StatefulWidget {
  const MonthViewPageDemo({super.key});

  @override
  _MonthViewPageDemoState createState() => _MonthViewPageDemoState();
}

class _MonthViewPageDemoState extends State<MonthViewPageDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Month View Demo')),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        elevation: 8,
        onPressed: () {},
        // TODO
        // onPressed: () => context.pushRoute(CreateEventPage()),
      ),
      body: MonthViewWidget(),
    );
  }
}
