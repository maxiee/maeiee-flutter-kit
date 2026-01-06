import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/controllers/command_palette_controller.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';

class CommandPalette extends StatelessWidget {
  const CommandPalette({super.key});

  @override
  Widget build(BuildContext context) {
    // 注入 Controller (仅在弹窗生命周期内有效)
    final c = Get.put(CommandPaletteController());

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 1. 全屏模糊背景 (点击关闭)
          GestureDetector(
            onTap: () => Get.back(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),

          // 2. 居中悬浮窗
          Align(
            alignment: const Alignment(0, -0.6), // 稍微靠上
            child: Container(
              width: 500,
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F),
                border: Border.all(color: AppColors.accentMain),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentMain.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Input
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.terminal, color: AppColors.accentMain),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            autofocus: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Courier',
                            ),
                            decoration: const InputDecoration(
                              hintText: "Type command or search...",
                              hintStyle: TextStyle(color: Colors.white24),
                              border: InputBorder.none,
                            ),
                            onChanged: c.onSearchChanged,
                            onSubmitted: (_) {
                              // 回车默认行为：如果有结果选第一个，没结果则创建
                              if (c.results.isNotEmpty) {
                                c.onSelect(c.results.first);
                              } else {
                                c.quickCreate();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const RpgDivider(height: 1),

                  // Results List
                  Flexible(
                    child: Obx(() {
                      // 模式 A: 显示搜索结果
                      if (c.results.isNotEmpty) {
                        return ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: c.results.length,
                          itemBuilder: (ctx, i) =>
                              _buildResultItem(c.results[i], c),
                        );
                      }

                      // 模式 B: 显示创建建议
                      if (c.searchText.isNotEmpty) {
                        return _buildCreateOption(c);
                      }

                      // 模式 C: 空状态
                      return const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          "WAITING FOR INPUT...",
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Courier',
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(SearchResult item, CommandPaletteController c) {
    IconData icon;
    Color color;

    if (item.type == ResultType.project) {
      icon = Icons.folder;
      color = AppColors.accentMain;
    } else {
      icon = Icons.check_circle_outline;
      color = Colors.white;
    }

    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        item.title,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Courier',
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        item.subtitle,
        style: TextStyle(color: color.withOpacity(0.5), fontSize: 10),
      ),
      hoverColor: color.withOpacity(0.1),
      onTap: () => c.onSelect(item),
    );
  }

  Widget _buildCreateOption(CommandPaletteController c) {
    return ListTile(
      leading: const Icon(Icons.add, color: AppColors.accentSafe),
      title: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'Courier', color: Colors.white),
          children: [
            const TextSpan(text: "Create Task: "),
            TextSpan(
              text: c.searchText.value,
              style: const TextStyle(
                color: AppColors.accentSafe,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      subtitle: const Text(
        "Add to Inbox",
        style: TextStyle(color: Colors.grey, fontSize: 10),
      ),
      hoverColor: AppColors.accentSafe.withOpacity(0.1),
      onTap: c.quickCreate,
    );
  }
}
