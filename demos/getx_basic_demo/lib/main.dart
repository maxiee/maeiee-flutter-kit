import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_basic_demo/app/routes/app_routes.dart';
import 'package:getx_basic_demo/app/services/todo_service.dart';

void main() {
  runApp(const MyApp());
}

// 初始化全局服务
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(TodoService());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GetX Basic Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      // 首页路由
      initialRoute: Routes.HOME,
      // 路由表
      getPages: AppPages.pages,
      // 初始化全局服务
      initialBinding: AppBinding(),
      // 按需开启日志
      enableLog: kDebugMode,
      // 默认专场动画
      defaultTransition: Transition.cupertino,
    );
  }
}
