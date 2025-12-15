import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// 赛博风格 Tab 选项卡 (非 Material TabBar)
/// 用于局部状态切换，如 Dialog 内部
class RpgTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const RpgTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = selectedIndex == index;
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: InkWell(
            onTap: () => onTabSelected(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? AppColors.accentMain
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  color: isSelected ? AppColors.accentMain : Colors.grey,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
