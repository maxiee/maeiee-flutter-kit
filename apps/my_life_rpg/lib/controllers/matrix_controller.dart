import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'game_controller.dart';
import '../models/quest.dart';

class MatrixController extends GetxController {
  final GameController _game = Get.find();

  // 交互状态
  final selectionStart = RxnInt(); // 第一次点击的格子索引
  final selectionEnd = RxnInt(); // 第二次点击的格子索引

  // 新方法：直接根据 Quest ID 获取颜色类型
  String? getQuestColorType(String questId) {
    final quest = _game.quests.firstWhereOrNull((q) => q.id == questId);
    if (quest == null) return null;
    return quest.type == QuestType.daemon ? 'cyan' : 'orange';
  }

  // 处理点击
  void onBlockTap(int index) {
    // 状态机：
    // 0. 初始状态 -> 设置 Start
    // 1. 已有 Start -> 设置 End -> 触发弹窗
    // 2. 已有 Start/End -> 重置

    if (selectionStart.value == null) {
      selectionStart.value = index;
      selectionEnd.value = null; // 清空之前的结束点
    } else if (selectionEnd.value == null) {
      // 确定范围
      int start = selectionStart.value!;
      int end = index;
      if (start > end) {
        // 如果反向选择，自动交换
        final temp = start;
        start = end;
        end = temp;
      }
      selectionStart.value = start;
      selectionEnd.value = end;

      // 触发添加逻辑
      _showAddLogDialog(start, end);
    } else {
      // 重置，重新开始选
      selectionStart.value = index;
      selectionEnd.value = null;
    }
  }

  void _showAddLogDialog(int start, int end) {
    // 计算时间字符串
    final startH = start ~/ 4;
    final startM = (start % 4) * 15;
    final endH = (end + 1) ~/ 4; // end是闭区间，所以时间要是下一个格子的开始
    final endM = ((end + 1) % 4) * 15;

    final timeStr =
        "${_fmt(startH)}:${_fmt(startM)} - ${_fmt(endH)}:${_fmt(endM)}";

    Get.defaultDialog(
      title: "ALLOCATE TIME",
      titleStyle: const TextStyle(
        fontFamily: 'Courier',
        color: GetColors.white,
      ),
      backgroundColor: const Color(0xFF1E1E1E),
      content: Column(
        children: [
          Text(
            "Target: $timeStr",
            style: const TextStyle(
              color: GetColors.grey,
              fontFamily: 'Courier',
            ),
          ),
          const SizedBox(height: 20),
          // 这里可以复用 QuestEditor 或者简易输入
          const Text(
            "TODO: Link to Quest or Create New",
            style: TextStyle(color: GetColors.white30),
          ),
        ],
      ),
      textConfirm: "CONFIRM",
      textCancel: "CANCEL",
      confirmTextColor: GetColors.black,
      onConfirm: () {
        // TODO: 实现手动补录逻辑
        // 比如：创建一个手动 Log，并标记 duration
        Get.back();
        // 清空选择
        selectionStart.value = null;
        selectionEnd.value = null;
      },
      onCancel: () {
        selectionStart.value = null;
        selectionEnd.value = null;
      },
    );
  }

  String _fmt(int n) => n.toString().padLeft(2, '0');

  bool isSelected(int index) {
    if (selectionStart.value == null) return false;
    if (selectionEnd.value == null) return index == selectionStart.value;
    return index >= selectionStart.value! && index <= selectionEnd.value!;
  }
}

// 简单的颜色别名，方便 View 使用
class GetColors {
  static const white = Color(0xFFFFFFFF);
  static const white30 = Colors.white30;
  static const grey = Colors.grey;
  static const black = Colors.black;
}
