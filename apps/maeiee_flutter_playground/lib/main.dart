import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:maeiee_flutter_playground/module/calendar_view/calendar_init_data_page.dart';
import 'package:maeiee_flutter_playground/module/calendar_view/day/day_view_page.dart';
import 'package:maeiee_flutter_playground/module/calendar_view/month/month_view_page.dart';
import 'package:maeiee_flutter_playground/module/calendar_view/multi_day/multi_day_view_page.dart';
import 'package:maeiee_flutter_playground/module/calendar_view/week/week_view_page.dart';
import 'package:maeiee_flutter_playground/module/dynamic/d4rx/pages/d4rx_bridge_page.dart';
import 'package:maeiee_flutter_playground/module/dynamic/d4rx/pages/d4rx_page.dart';
import 'package:maeiee_flutter_playground/module/dynamic/flutter_d4rx/pages/flutter_d4rt_custom_simple_page.dart';
import 'package:maeiee_flutter_playground/module/dynamic/flutter_d4rx/pages/flutter_d4rt_webview_page.dart';
import 'package:maeiee_flutter_playground/module/dynamic/flutter_d4rx/pages/flutter_d4rx_page.dart';
import 'package:maeiee_flutter_playground/module/listview/itemextend_optimise/itemextend_optimise_page.dart';
import 'package:maeiee_flutter_playground/module/listview/principle/lazy_sliver/lazy_sliver_demo.dart';
import 'package:maeiee_flutter_playground/module/listview/principle/lazy_sliver_v2/lazy_sliver_demo_v2.dart';
import 'package:maeiee_flutter_playground/module/listview/principle/scrollable_demo.dart';
import 'package:maeiee_flutter_playground/module/listview/principle/sliver/sliver_protocol_demo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // flutter_calendar_view 需要在最外层包裹 CalendarControllerProvider
    final isDarkMode =
        WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
    return CalendarThemeProvider(
      calendarTheme: CalendarThemeData(
        monthViewTheme: isDarkMode
            ? MonthViewThemeData.dark()
            : MonthViewThemeData.light(),
        dayViewTheme: isDarkMode
            ? DayViewThemeData.dark()
            : DayViewThemeData.light(),
        weekViewTheme: isDarkMode
            ? WeekViewThemeData.dark()
            : WeekViewThemeData.light(),
        multiDayViewTheme: isDarkMode
            ? MultiDayViewThemeData.dark()
            : MultiDayViewThemeData.light(),
      ),
      child: CalendarControllerProvider(
        controller: EventController(),
        child: MaterialApp(
          title: 'Maeiee Flutter Playground',
          routes: {
            '/scrollable_demo': (context) => const PureScrollableDemo(),
            '/sliver_protocol_demo': (context) => const SliverProtocolDemo(),
            '/listview_itemextend_optimise': (context) =>
                const ItemextendOptimisePage(),
            '/lazy_sliver_demo': (context) => const LazySliverDemo(),
            '/advanced_sliver_demo': (context) =>
                const AdvancedLazySliverDemo(),
            '/d4rx': (context) => const D4rxPage(),
            '/d4rx_bridge': (context) => const D4rxBridgePage(),
            '/flutter_d4rx': (context) => const FlutterD4rxPage(),
            '/flutter_d4rx_custom_simple': (context) =>
                const FlutterD4rtCustomSimplePage(),
            '/flutter_d4rt_webview': (context) =>
                const FlutterD4rtWebviewPage(),
            '/calendar_init_data': (context) => const CalendarInitDataPage(),
            '/day_view_demo': (context) => const DayViewPageDemo(),
            '/multi_day_view_demo': (context) => const MultiDayViewDemo(),
            '/week_view_demo': (context) => const WeekViewDemo(),
            '/month_view_demo': (context) => const MonthViewPageDemo(),
          },
          theme: ThemeData(
            colorScheme: .fromSeed(seedColor: Colors.deepPurple),
          ),
          home: const MyHomePage(title: 'Flutter Demo Home Page'),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/scrollable_demo'),
              child: Text("纯 Scrollable 简易 ListView"),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/sliver_protocol_demo'),
              child: Text("Sliver 协议示例"),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/lazy_sliver_demo'),
              child: Text("Lazy Loading Sliver 示例"),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/advanced_sliver_demo'),
              child: Text("Advanced Lazy Sliver 示例"),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(
                context,
              ).pushNamed('/listview_itemextend_optimise'),
              child: Text("ListView ItemExtend 优化示例"),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/calendar_init_data'),
              child: Text("Calendar View 初始化数据示例"),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/day_view_demo'),
              child: Text("Calendar View 日视图示例"),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/multi_day_view_demo'),
              child: Text("Calendar View 多日视图示例"),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/week_view_demo'),
              child: Text("Calendar View 周视图示例"),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/month_view_demo'),
              child: Text("Calendar View 月视图示例"),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pushNamed('/d4rx'),
              child: Text("d4rx：Dart 动态化"),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pushNamed('/d4rx_bridge'),
              child: Text("d4rx Bridge：Dart 动态化桥接示例"),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pushNamed('/flutter_d4rx'),
              child: Text("flutter_d4rx：Flutter 动态化"),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(
                context,
              ).pushNamed('/flutter_d4rx_custom_simple'),
              child: Text("flutter_d4rx：Flutter 桥接预埋简单组件示例"),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/flutter_d4rt_webview'),
              child: Text("flutter_d4rx：Flutter 桥接 WebView 示例"),
            ),
          ],
        ),
      ),
    );
  }
}
