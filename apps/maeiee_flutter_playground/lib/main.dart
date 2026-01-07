import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:maeiee_flutter_playground/module/calendar_view/calendar_init_data_page.dart';
import 'package:maeiee_flutter_playground/module/calendar_view/month/month_view_page.dart';
import 'package:maeiee_flutter_playground/module/dynamic/d4rx/pages/d4rx_bridge_page.dart';
import 'package:maeiee_flutter_playground/module/dynamic/d4rx/pages/d4rx_page.dart';
import 'package:maeiee_flutter_playground/module/dynamic/flutter_d4rx/pages/flutter_d4rt_custom_simple_page.dart';
import 'package:maeiee_flutter_playground/module/dynamic/flutter_d4rx/pages/flutter_d4rt_webview_page.dart';
import 'package:maeiee_flutter_playground/module/dynamic/flutter_d4rx/pages/flutter_d4rx_page.dart';
import 'package:maeiee_flutter_playground/module/listview/itemextend_optimise/itemextend_optimise_page.dart';
import 'package:maeiee_flutter_playground/module/listview/principle/scrollable_demo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // flutter_calendar_view 需要在最外层包裹 CalendarControllerProvider
    return CalendarControllerProvider(
      controller: EventController(),
      child: MaterialApp(
        title: 'Maeiee Flutter Playground',
        routes: {
          '/scrollable_demo': (context) => const PureScrollableDemo(),
          '/listview_itemextend_optimise': (context) =>
              const ItemextendOptimisePage(),
          '/d4rx': (context) => const D4rxPage(),
          '/d4rx_bridge': (context) => const D4rxBridgePage(),
          '/flutter_d4rx': (context) => const FlutterD4rxPage(),
          '/flutter_d4rx_custom_simple': (context) =>
              const FlutterD4rtCustomSimplePage(),
          '/flutter_d4rt_webview': (context) => const FlutterD4rtWebviewPage(),
          '/calendar_init_data': (context) => const CalendarInitDataPage(),
          '/month_view_demo': (context) => const MonthViewPageDemo(),
        },
        theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
