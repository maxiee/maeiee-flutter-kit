import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/controllers/mission_controller.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/views/home/widgets/campaign_bar.dart';
import 'package:my_life_rpg/views/home/widgets/matrix/temporal_matrix.dart';
import '../../controllers/game_controller.dart';
import 'widgets/hud/player_hud.dart';
import 'widgets/panels/mission_panel.dart';

class HomeView extends StatelessWidget {
  final GameController c = Get.put(GameController());
  final MissionController mc = Get.put(MissionController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDarker,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.paddingSm,
          child: Column(
            children: [
              // 1. 顶部玩家状态 (HUD)
              Expanded(flex: 2, child: PlayerHud()),

              AppSpacing.gapV8,

              // 2. Project Bar (固定高度)
              CampaignBar(),

              AppSpacing.gapV8,

              // 3. Split Panel (Flex 8)
              Expanded(
                flex: 8,
                child: Row(
                  children: [
                    Expanded(flex: 6, child: MissionPanel()), // 任务板
                    AppSpacing.gapH8,
                    // 右侧：时空矩阵
                    Expanded(flex: 4, child: TemporalMatrix()),
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
