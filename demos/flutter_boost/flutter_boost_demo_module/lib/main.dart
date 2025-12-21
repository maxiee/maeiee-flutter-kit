import 'package:flutter/material.dart';
import 'package:flutter_boost/flutter_boost.dart';

void main() {
  /// 关键点1：必须添加 CustomFlutterBinding，用于接管生命周期
  CustomFlutterBinding();
  runApp(const MyApp());
}

/// 关键点1实现：自定义 Binding，混入 BoostFlutterBinding
class CustomFlutterBinding extends WidgetsFlutterBinding
    with BoostFlutterBinding {}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// 关键点2：路由表映射
  /// 这里定义页面名称 (Key) 到页面构建逻辑 (Value) 的映射
  Map<String, FlutterBoostRouteFactory> routerMap = {
    // 首页
    '/': (settings, isInitialRoute, uniqueId) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const HomePage(),
      );
    },
    // 一个简单的测试页
    'simplePage': (settings, isInitialRoute, uniqueId) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const SimplePage(),
      );
    },
  };

  /// 路由工厂函数
  Route<dynamic>? routeFactory(
    RouteSettings settings,
    bool isInitialRoute,
    String? uniqueId,
  ) {
    FlutterBoostRouteFactory? func = routerMap[settings.name];
    if (func == null) return null;
    return func(settings, isInitialRoute, uniqueId);
  }

  @override
  Widget build(BuildContext context) {
    /// 关键点3：使用 FlutterBoostApp 作为顶层 Widget
    return FlutterBoostApp(
      routeFactory,
      appBuilder: (home) => MaterialApp(
        home: home,
        debugShowCheckedModeBanner: true,
        builder: (_, __) => home, // 必须加上 builder，否则弹窗可能出错
      ),
    );
  }
}

// --- 以下是两个简单的测试页面 ---

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Home')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              child: const Text('跳转到 Native 页面'),
              onPressed: () {
                // 跳转到原生页面
                BoostNavigator.instance.push(
                  "nativePage",
                  arguments: {"msg": "来自Flutter"},
                );
              },
            ),
            // 内部路由 (推荐) siplePage
            ElevatedButton(
              child: const Text('跳转到 Flutter 页面'),
              onPressed: () {
                // 跳转到 Flutter 页面
                BoostNavigator.instance.push("simplePage");
              },
            ),
            // 新容器路由 siplePage
            ElevatedButton(
              child: const Text('新容器跳转到 Flutter 页面'),
              onPressed: () {
                // 新容器跳转到 Flutter 页面
                BoostNavigator.instance.push("simplePage", withContainer: true);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SimplePage extends StatelessWidget {
  const SimplePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Page')),
      body: const Center(child: Text('This is a Flutter Page')),
    );
  }
}
