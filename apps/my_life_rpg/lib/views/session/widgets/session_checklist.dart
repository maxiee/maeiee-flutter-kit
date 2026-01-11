import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/controllers/session_controller.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';

class SessionChecklist extends StatelessWidget {
  const SessionChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionController c = Get.find();

    return Obx(() {
      final checklist = c.quest.checklist;

      // 如果没有子任务，不显示此区域，或者显示一个占位符鼓励拆解？
      // 为了节省空间，没有就不显示
      if (checklist.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black38,
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(4),
        ),
        // 限制高度，如果太长可以滚动，避免挤压日志区
        constraints: const BoxConstraints(maxHeight: 160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.list_alt, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                const Text(
                  "TACTICAL SEQUENCE",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  "${checklist.where((e) => e.isCompleted).length}/${checklist.length}",
                  style: const TextStyle(
                    color: AppColors.accentMain,
                    fontSize: 10,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: checklist.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (ctx, i) {
                  final item = checklist[i];
                  return InkWell(
                    onTap: () => c.toggleSubTask(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          // Checkbox visual
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: item.isCompleted
                                  ? AppColors.accentSafe.withOpacity(0.2)
                                  : Colors.transparent,
                              border: Border.all(
                                color: item.isCompleted
                                    ? AppColors.accentSafe
                                    : Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: item.isCompleted
                                ? const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: AppColors.accentSafe,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          // Text
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: item.isCompleted
                                    ? Colors.grey
                                    : Colors.white,
                                fontSize: 13,
                                decoration: item.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
