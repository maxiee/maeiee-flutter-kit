import 'package:flutter/material.dart';
import 'package:my_life_rpg/views/home/widgets/matrix/date_controller_bar.dart';
import 'package:my_life_rpg/views/home/widgets/nav/direction_rail.dart';
import 'package:my_life_rpg/views/home/widgets/nav/project_sidebar.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';
import 'package:my_life_rpg/views/home/widgets/matrix/home_day_calendar.dart';
import 'widgets/hud/player_hud.dart';
import 'widgets/panels/mission_panel.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDarker,
      body: SafeArea(
        child: Column(
          children: [
            // 1. 顶部玩家状态 (HUD) - 保持不变，但高度可以稍微压缩一点
            SizedBox(
              height: 100,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: PlayerHud(),
              ),
            ),

            // 2. 主工作区 (Main Workspace) - 采用 Row 布局
            Expanded(
              flex: 10,
              child: Row(
                children: [
                  // A. Level 1: Direction Rail
                  DirectionRail(),

                  // B. Level 2: Project Sidebar (Conditional)
                  ProjectSidebar(),

                  // C. Level 3: Missions & Matrix
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          // 任务列表
                          Expanded(flex: 6, child: MissionPanel()),

                          AppSpacing.gapH8,

                          // 时空矩阵
                          Expanded(
                            flex: 4,
                            child: RpgContainer(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  DateControllerBar(),
                                  Expanded(child: HomeDayCalendar()),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
