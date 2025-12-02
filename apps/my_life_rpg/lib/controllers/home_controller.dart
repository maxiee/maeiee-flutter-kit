import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/services/player_service.dart';
import 'package:my_life_rpg/views/home/overlay/level_up_overlay.dart';

class HomeController extends GetxController {
  final PlayerService _ps = Get.find();

  @override
  void onInit() {
    super.onInit();

    // 监听升级流
    // 我们在 TimeService 里把 _levelUpEvent 设为了 Rxn<int>，
    // 我们可以通过 getter 暴露这个 Rxn 对象本身，而不是 .stream

    // 假设 TimeService 修改如下：
    // Rxn<int> get levelUpEvent => _levelUpEvent;

    // 这里先用流监听演示 (万能)
    _ps.onLevelUp.listen((newLevel) {
      if (newLevel != null) {
        // [优化] 延迟 300ms，让用户先看到任务创建成功的反馈（矩阵格子变色）
        // 然后再弹出惊喜，体验更有层次感
        Future.delayed(const Duration(milliseconds: 300), () {
          _showLevelUpDialog(newLevel);
        });
      }
    });
  }

  void _showLevelUpDialog(int level) {
    // 使用 Get.dialog 显示全屏覆盖
    Get.dialog(
      LevelUpOverlay(
        newLevel: level,
        onDismiss: () => Get.back(), // 关闭弹窗
      ),
      barrierDismissible: false, // 必须点击内部
      barrierColor: Colors.transparent, // Overlay 自带背景色
    );
  }
}
