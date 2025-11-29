import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'game_controller.dart';
import '../models/quest.dart';

class MatrixController extends GetxController {
  final GameController _game = Get.find();

  // 交互状态
  final selectionStart = RxnInt(); // 第一次点击的格子索引
  final selectionEnd = RxnInt(); // 第二次点击的格子索引

  // 弹窗里的状态
  final RxString selectedQuestId = ''.obs;
  final RxString newQuestTitle = ''.obs;
  final RxBool isCreatingNew = false.obs;

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

  String _fmt(int n) => n.toString().padLeft(2, '0');

  bool isSelected(int index) {
    if (selectionStart.value == null) return false;
    if (selectionEnd.value == null) return index == selectionStart.value;
    return index >= selectionStart.value! && index <= selectionEnd.value!;
  }

  void _showAddLogDialog(int start, int end) {
    // 1. 计算具体的 DateTime 对象 (基于 selectedDate)
    final date = _game.selectedDate.value;
    final startH = start ~/ 4;
    final startM = (start % 4) * 15;
    final endH = (end + 1) ~/ 4;
    final endM =
        ((end + 1) % 4) * 15; // 注意这里如果是 24:00 需要特殊处理，DateTime支持 hour=24 自动进位吗？
    // DateTime 的 hour 范围是 0-23。如果 endBlock 是 95，结束时间是次日 00:00。

    // 构造 DateTime
    final startTime = DateTime(date.year, date.month, date.day, startH, startM);
    // 处理跨天逻辑 (24:00)
    DateTime endTime;
    if (endH == 24) {
      endTime = DateTime(date.year, date.month, date.day + 1, 0, 0);
    } else {
      endTime = DateTime(date.year, date.month, date.day, endH, endM);
    }

    final timeStr =
        "${_fmt(startH)}:${_fmt(startM)} - ${_fmt(endH)}:${_fmt(endM)}";

    // 默认选中第一个任务 (如果有)
    if (_game.quests.isNotEmpty) {
      selectedQuestId.value = _game.quests.first.id;
    }

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Colors.white24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                "ALLOCATE TIME SEGMENT",
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                timeStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Courier',
                ),
              ),
              const SizedBox(height: 20),

              // Tabs (Switch between Existing / New)
              Obx(
                () => Row(
                  children: [
                    _buildTab(
                      "EXISTING QUEST",
                      !isCreatingNew.value,
                      () => isCreatingNew.value = false,
                    ),
                    const SizedBox(width: 12),
                    _buildTab(
                      "CREATE NEW",
                      isCreatingNew.value,
                      () => isCreatingNew.value = true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Content
              Obx(() {
                if (isCreatingNew.value) {
                  // Mode: Create New
                  return TextField(
                    onChanged: (v) => newQuestTitle.value = v,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Courier',
                    ),
                    decoration: const InputDecoration(
                      labelText: "NEW QUEST TITLE",
                      labelStyle: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Courier',
                      ),
                      filled: true,
                      fillColor: Colors.black38,
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  );
                } else {
                  // Mode: Select Existing
                  // 过滤掉已完成的，或者只显示最近活跃的？ MVP 显示全部 active
                  final activeQuests = _game.quests
                      .where((q) => !q.isCompleted)
                      .toList();

                  if (activeQuests.isEmpty) {
                    return const Text(
                      "NO ACTIVE QUESTS. CREATE NEW ONE.",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontFamily: 'Courier',
                      ),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value:
                            activeQuests.any(
                              (q) => q.id == selectedQuestId.value,
                            )
                            ? selectedQuestId.value
                            : null,
                        dropdownColor: const Color(0xFF252525),
                        isExpanded: true,
                        items: activeQuests
                            .map(
                              (q) => DropdownMenuItem(
                                value: q.id,
                                child: Text(
                                  q.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Courier',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) selectedQuestId.value = val;
                        },
                      ),
                    ),
                  );
                }
              }),

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Get.back();
                      selectionStart.value = null;
                      selectionEnd.value = null;
                    },
                    child: const Text(
                      "CANCEL",
                      style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      if (isCreatingNew.value) {
                        // 1. 新建任务
                        if (newQuestTitle.value.trim().isEmpty) return;
                        _game.addNewQuest(
                          title: newQuestTitle.value,
                          type: QuestType.mission,
                        ); // 没法拿到返回值ID，这是个小问题
                        // 临时解法：addNewQuest 改为返回 Quest 对象，或者获取 quests.last
                        final newQ = _game.quests.last;
                        _game.manualAllocate(newQ.id, startTime, endTime);
                      } else {
                        // 2. 使用现有任务
                        if (selectedQuestId.value.isEmpty) return;
                        _game.manualAllocate(
                          selectedQuestId.value,
                          startTime,
                          endTime,
                        );
                      }

                      Get.back();
                      selectionStart.value = null;
                      selectionEnd.value = null;
                    },
                    child: const Text(
                      "CONFIRM",
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.orangeAccent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.orangeAccent : Colors.grey,
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
