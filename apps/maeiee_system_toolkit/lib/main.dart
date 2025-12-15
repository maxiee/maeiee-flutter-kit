import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:maeiee_system_toolkit/core/data/initial_binding.dart';
import 'package:maeiee_system_toolkit/views/home/home_binding.dart';
import 'package:maeiee_system_toolkit/views/home/home_view.dart';
import 'package:maeiee_system_toolkit/views/repo_to_prompt/repo_to_prompt_binding.dart';
import 'package:maeiee_system_toolkit/views/repo_to_prompt/repo_to_prompt_view.dart';
import 'package:rpg_cyber_ui/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Maeiee System Toolkit',
      initialBinding: InitialBinding(),
      initialRoute: '/home',
      getPages: [
        GetPage(
          name: '/home',
          page: () => const HomeView(),
          binding: HomeBinding(),
        ),
        GetPage(
          name: '/repo_to_prompt',
          page: () => const RepoToPromptView(),
          binding: RepoToPromptBinding(),
        ),
      ],
      theme: AppTheme.darkTheme,
    );
  }
}
