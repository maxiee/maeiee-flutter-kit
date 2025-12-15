import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';
import 'package:my_life_rpg/core/utils/logger.dart';

class DebugConsole extends StatelessWidget {
  final LogService logger = Get.find();

  DebugConsole({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        height: 300,
        margin: const EdgeInsets.only(top: 40, left: 20, right: 20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          border: Border.all(color: AppColors.accentSystem),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: AppColors.accentSystem.withOpacity(0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "SYSTEM TERMINAL",
                    style: TextStyle(
                      color: AppColors.accentSystem,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    onTap: () => Get.back(),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.accentSystem,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Log List
            Expanded(
              child: Obx(
                () => ListView.builder(
                  padding: const EdgeInsets.all(8),
                  reverse: true, // 最新在下？不，通常最新在下，但 ListView reverse 是最新在上
                  // 我们希望最新在底部，类似 Terminal
                  // 这里的 logs 是 append 的，所以 index 0 是最老的
                  // 为了让它像终端一样滚动到底部，我们可以 reverse: true，然后渲染时倒序取值
                  // 或者简单点，直接渲染，让它自己顶上去
                  itemCount: logger.logs.length,
                  itemBuilder: (ctx, i) {
                    // 反转索引，显示最新的在最下面
                    // 实际上 ListView reverse=true 时，index 0 在最底部
                    // 我们的 logs.last 是最新的
                    // 所以 logs[logs.length - 1 - i]
                    final entry = logger.logs[logger.logs.length - 1 - i];
                    return _buildLogLine(entry);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogLine(LogEntry entry) {
    Color color;
    switch (entry.level) {
      case LogLevel.error:
        color = Colors.red;
        break;
      case LogLevel.warning:
        color = Colors.yellow;
        break;
      case LogLevel.debug:
        color = Colors.grey;
        break;
      default:
        color = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'Courier', fontSize: 10),
          children: [
            TextSpan(
              text: "[${entry.timeStr}] ",
              style: const TextStyle(color: Colors.grey),
            ),
            if (entry.tag != null)
              TextSpan(
                text: "${entry.tag}: ",
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            TextSpan(
              text: entry.message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
