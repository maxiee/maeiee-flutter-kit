import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/controllers/mission_controller.dart';
import 'package:my_life_rpg/services/task_service.dart';
import 'package:my_life_rpg/views/home/widgets/command_palette.dart';
import 'package:my_life_rpg/views/settings/settings_view.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';

class DirectionRail extends StatelessWidget {
  final MissionController mc = Get.find();
  final TaskService qs = Get.find();

  DirectionRail({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68, // 固定宽度
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A), // 深黑背景
        border: Border(right: BorderSide(color: AppColors.borderDim)),
      ),
      child: Column(
        children: [
          // CORTEX LINK 入口
          _buildSearchIcon(),

          // --- 全局过滤器 ---
          _buildGlobalIcon(
            Icons.inbox,
            "inbox",
            "INBOX",
            countProvider: () =>
                qs.projects.where((p) => p.directionId == null).length,
          ),
          _buildGlobalIcon(
            Icons.warning_amber,
            "urgent",
            "URGENT",
            color: AppColors.accentDanger,
          ),
          _buildGlobalIcon(
            Icons.loop,
            "daemon",
            "DAEMONS",
            color: AppColors.accentSystem,
          ),

          const RpgDivider(height: 1),

          // --- 战略方向 (Directions) ---
          Expanded(
            child: Obx(
              () => ListView.separated(
                itemCount: qs.directions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final dir = qs.directions[i];
                  return _buildDirectionIcon(dir);
                },
              ),
            ),
          ),

          // --- 底部设置/新增 ---
          const RpgDivider(height: 1),
          _buildSettingsButton(),
        ],
      ),
    );
  }

  Widget _buildGlobalIcon(
    IconData icon,
    String filterType,
    String tooltip, {
    Color? color,
    int Function()? countProvider, // 可选的计数回调
  }) {
    return Obx(() {
      final isSelected =
          mc.viewMode.value == ViewMode.global &&
          mc.globalFilterType.value == filterType;

      final activeColor = color ?? Colors.white;

      // 只有 Inbox 我们统计项目数，其他的是任务视图，暂不显示角标以免混淆概念
      final count = countProvider?.call() ?? 0;

      return _buildRailItem(
        isSelected: isSelected,
        color: activeColor,
        icon: icon,
        tooltip: tooltip,
        badgeCount: count,
        onTap: () => mc.setGlobalFilter(filterType),
      );
    });
  }

  Widget _buildDirectionIcon(dynamic dir) {
    return Obx(() {
      final isSelected =
          mc.viewMode.value == ViewMode.hierarchy &&
          mc.selectedDirectionId.value == dir.id;

      // 实时计算该方向下的项目数
      final projectCount = qs.projects
          .where((p) => p.directionId == dir.id)
          .length;

      return _buildRailItem(
        isSelected: isSelected,
        color: dir.color,
        icon: dir.icon,
        tooltip: dir.title,
        badgeCount: projectCount,
        onTap: () => mc.selectDirection(dir.id),
      );
    });
  }

  // 统一的侧边栏按钮构建器
  Widget _buildRailItem({
    required bool isSelected,
    required Color color,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Tooltip(
      message: tooltip,
      preferBelow: false, // 侧边栏 tooltip 最好显示在侧面，但 Material 默认行为可能受限
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 44, // [修改] 增加高度，更容易点击
            width: double.infinity, // 填满宽度
            padding: const EdgeInsets.symmetric(horizontal: 4), // 内容内缩一点
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. 背景高亮块
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44, // 视觉宽度
                  height: 44, // 视觉高度
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected
                        ? Border.all(color: color.withOpacity(0.5))
                        : Border.all(color: Colors.transparent),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? color : Colors.white24,
                    size: 24, // 图标稍微大一点点
                  ),
                ),

                // 3. 数量角标 (Cyberpunk Style)
                if (badgeCount > 0)
                  Positioned(
                    top: 4, // 稍微靠上
                    right: 4, // 稍微靠右
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black, // 黑底
                        border: Border.all(
                          color: color.withOpacity(0.7),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(2), // 硬朗的圆角
                      ),
                      constraints: const BoxConstraints(minWidth: 14),
                      alignment: Alignment.center,
                      child: Text(
                        "$badgeCount",
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier', // 等宽字体更像代码
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchIcon() {
    return Tooltip(
      message: "CORTEX LINK (Global Search)",
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // 使用 Get.dialog 显示模态层
          onTap: () => Get.dialog(
            const CommandPalette(),
            barrierColor: Colors.transparent, // 我们的组件自带了 BackdropFilter
            barrierDismissible: true,
            transitionDuration: const Duration(milliseconds: 150),
          ),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 44,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              decoration: BoxDecoration(
                // color: AppColors.accentMain.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  // color: AppColors.accentMain.withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.search,
                color: AppColors.accentMain,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 底部设置按钮组件
  Widget _buildSettingsButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Tooltip(
        message: "SYSTEM CONFIG",
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Get.to(() => const SettingsView()),
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 48,
              height: 48,
              child: const Icon(Icons.settings, color: Colors.grey, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}
