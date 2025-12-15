import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // 别忘了这个
import 'package:my_life_rpg/core/data/data_seeder.dart';
import 'package:my_life_rpg/core/data/initial_binding.dart';
import 'package:rpg_cyber_ui/theme/app_theme.dart';
import 'package:my_life_rpg/views/home/home_binding.dart';
import 'package:my_life_rpg/views/home/home_view.dart';

void main() async {
  await GetStorage.init(); // 确保存储初始化
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'My Life RPG',
      initialBinding: InitialBinding(),
      onReady: () {
        DataSeeder.run();
      },
      initialRoute: '/home',
      getPages: [
        GetPage(
          name: '/home',
          page: () => HomeView(),
          binding: HomeBinding(), // [关键] 绑定控制器
        ),
      ],
      theme: AppTheme.darkTheme, // 使用统一的赛博朋克主题
    );
  }
}
