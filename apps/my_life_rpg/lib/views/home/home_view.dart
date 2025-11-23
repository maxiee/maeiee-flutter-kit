import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/views/home/widgets/campaign_bar.dart';
import '../../controllers/game_controller.dart';
import 'widgets/player_hud.dart';
import 'widgets/mission_panel.dart';
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

              // 2. Project Bar (固定高度)
              CampaignBar(),

              const SizedBox(height: 8),

              // 3. Split Panel (Flex 8)
              Expanded(
                flex: 8,
                child: Row(
                  children: [
                    Expanded(flex: 6, child: MissionPanel()), // 任务板
                    const SizedBox(width: 8),
                    Expanded(flex: 4, child: RoutinePanel()), // 守护进程
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
