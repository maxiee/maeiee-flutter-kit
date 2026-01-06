import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/controllers/mission_controller.dart';
import 'package:my_life_rpg/services/task_service.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';

class DirectionRail extends StatelessWidget {
  final MissionController mc = Get.find();
  final TaskService qs = Get.find();

  DirectionRail({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56, // 固定宽度
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A), // 深黑背景
        border: Border(right: BorderSide(color: AppColors.borderDim)),
      ),
      child: Column(
        children: [
          AppSpacing.gapV16,
          // --- 全局过滤器 ---
          _buildGlobalIcon(Icons.inbox, "inbox", "INBOX"),
          AppSpacing.gapV16,
          _buildGlobalIcon(
            Icons.warning_amber,
            "urgent",
            "URGENT",
            color: AppColors.accentDanger,
          ),
          AppSpacing.gapV16,
          _buildGlobalIcon(
            Icons.loop,
            "daemon",
            "DAEMONS",
            color: AppColors.accentSystem,
          ),

          AppSpacing.gapV16,
          const RpgDivider(height: 1),
          AppSpacing.gapV16,

          // --- 战略方向 (Directions) ---
          Expanded(
            child: Obx(
              () => ListView.separated(
                itemCount: qs.directions.length,
                separatorBuilder: (_, __) => AppSpacing.gapV16,
                itemBuilder: (ctx, i) {
                  final dir = qs.directions[i];
                  return _buildDirectionIcon(dir);
                },
              ),
            ),
          ),

          // --- 底部设置/新增 ---
          const RpgDivider(height: 1),
          // 这里可以放设置按钮，暂留空
          AppSpacing.gapV16,
        ],
      ),
    );
  }

  Widget _buildGlobalIcon(
    IconData icon,
    String filterType,
    String tooltip, {
    Color? color,
  }) {
    return Obx(() {
      final isSelected =
          mc.viewMode.value == ViewMode.global &&
          mc.globalFilterType.value == filterType;

      final activeColor = color ?? Colors.white;

      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () => mc.setGlobalFilter(filterType),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withOpacity(0.2)
                  : Colors.transparent,
              border: isSelected ? Border.all(color: activeColor) : null,
              borderRadius: BorderRadius.circular(4),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? activeColor : Colors.grey,
              size: 20,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDirectionIcon(dynamic dir) {
    // dir is Direction model
    return Obx(() {
      final isSelected =
          mc.viewMode.value == ViewMode.hierarchy &&
          mc.selectedDirectionId.value == dir.id;

      final color = dir.color;

      return Tooltip(
        message: dir.title,
        child: InkWell(
          onTap: () => mc.selectDirection(dir.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              // 选中时左侧亮条
              border: isSelected
                  ? Border(left: BorderSide(color: color, width: 3))
                  : null,
            ),
            child: Icon(
              dir.icon,
              color: isSelected ? color : Colors.white24,
              size: 22,
            ),
          ),
        ),
      );
    });
  }
}
