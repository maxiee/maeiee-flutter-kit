import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/game_controller.dart';
import 'widgets/player_hud.dart';
import 'widgets/project_panel.dart';
import 'widgets/routine_panel.dart';

class HomeView extends StatelessWidget {
  final GameController c = Get.put(GameController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // 极深灰背景，不像纯黑那么刺眼
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // 1. 顶部玩家状态 (HUD)
              Expanded(flex: 2, child: PlayerHud()),

              SizedBox(height: 8),

              // 2. 主体分栏 (Left: Projects, Right: Routines)
              Expanded(
                flex: 8,
                child: Row(
                  children: [
                    Expanded(flex: 6, child: ProjectPanel()), // 主线占宽一点
                    SizedBox(width: 8),
                    Expanded(flex: 4, child: RoutinePanel()), // 杂事占窄一点
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
