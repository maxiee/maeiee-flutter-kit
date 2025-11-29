import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/app_colors.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import 'package:my_life_rpg/services/time_service.dart';
import 'package:my_life_rpg/views/home/widgets/matrix/session_inspector.dart';
import 'package:my_life_rpg/views/home/widgets/matrix/time_allocation_dialog.dart';
import '../models/quest.dart';

class MatrixController extends GetxController {
  // 依赖注入：直接获取 Service
  final QuestService _questService = Get.find();
  final TimeService _timeService = Get.find();

  // 交互状态
  final selectionStart = RxnInt(); // 第一次点击的格子索引
  final selectionEnd = RxnInt(); // 第二次点击的格子索引

  void onBlockTap(int index) {
    final state = _timeService.timeBlocks[index];

    // [修改点]：分支判断
    if (state.occupiedSessionIds.isNotEmpty) {
      // 1. 点击了已占用的格子 -> 查看详情
      // 获取最上层的 session ID
      final sessionId = state.occupiedSessionIds.last;
      _showSessionDetail(sessionId);

      // 清除之前的补录选择状态，避免混淆
      selectionStart.value = null;
      selectionEnd.value = null;
    } else {
      // 2. 点击了空白格子 -> 走原来的补录逻辑
      _handleEmptyBlockTap(index);
    }
  }

  // 处理点击
  void _handleEmptyBlockTap(int index) {
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

  // [新增]：显示详情弹窗
  void _showSessionDetail(String sessionId) {
    final result = _questService.getSessionById(sessionId);
    if (result == null) return;

    final quest = result.quest;
    final session = result.session;

    Get.dialog(
      SessionInspector(quest: quest, session: session),
      barrierColor: Colors.black54,
    );
  }

  String _fmt(int n) => n.toString().padLeft(2, '0');

  bool isSelected(int index) {
    if (selectionStart.value == null) return false;
    if (selectionEnd.value == null) return index == selectionStart.value;
    return index >= selectionStart.value! && index <= selectionEnd.value!;
  }

  // [新增] 判断两个格子是否相连 (属于同一个非空 Session)
  bool isConnected(int indexA, int indexB) {
    if (indexA < 0 || indexA >= 96 || indexB < 0 || indexB >= 96) return false;

    final stateA = _timeService.timeBlocks[indexA];
    final stateB = _timeService.timeBlocks[indexB];

    // 如果都为空，不连
    if (stateA.occupiedSessionIds.isEmpty ||
        stateB.occupiedSessionIds.isEmpty) {
      return false;
    }

    // 如果最上层的 Session ID 相同，则相连
    return stateA.occupiedSessionIds.last == stateB.occupiedSessionIds.last;
  }

  void _showAddLogDialog(int start, int end) async {
    // 1. 计算时间 (逻辑保持不变)
    final date = _timeService.selectedDate.value;
    final startH = start ~/ 4;
    final startM = (start % 4) * 15;
    final endH = (end + 1) ~/ 4;
    final endM = ((end + 1) % 4) * 15;

    final startTime = DateTime(date.year, date.month, date.day, startH, startM);
    DateTime endTime;
    if (endH == 24) {
      endTime = DateTime(date.year, date.month, date.day + 1, 0, 0);
    } else {
      endTime = DateTime(date.year, date.month, date.day, endH, endM);
    }

    final timeStr =
        "${_fmt(startH)}:${_fmt(startM)} - ${_fmt(endH)}:${_fmt(endM)}";

    // 2. [重构点] 调用组件化 Dialog
    // 使用 await 等待用户操作结果
    final result = await Get.dialog(
      TimeAllocationDialog(
        timeRangeText: timeStr,
        startTime: startTime,
        endTime: endTime,
        questService: _questService,
      ),
      barrierColor: Colors.black54,
    );

    // 3. 处理结果
    // Reset selection regardless of result
    selectionStart.value = null;
    selectionEnd.value = null;

    if (result != null && result is Map) {
      final isNew = result['isNew'] as bool;

      if (isNew) {
        final title = result['title'] as String;
        final newQ = _questService.addNewQuest(
          title: title,
          type: QuestType.mission,
        );
        _questService.manualAllocate(newQ.id, startTime, endTime);
      } else {
        final qId = result['id'] as String;
        _questService.manualAllocate(qId, startTime, endTime);
      }
    }
  }

  Widget _buildTab(String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.accentMain : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.accentMain : Colors.grey,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// 简单的颜色别名，方便 View 使用
class GetColors {
  static const white = Color(0xFFFFFFFF);
  static const white30 = Colors.white30;
  static const grey = Colors.grey;
  static const black = Colors.black;
}
