import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // 别忘了这个
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
      theme: ThemeData.dark(), // 既然是黑色风格，直接全局 Dark
      home: HomeView(),
    );
  }
}
