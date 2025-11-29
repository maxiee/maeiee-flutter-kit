import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/app_colors.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import 'package:my_life_rpg/services/time_service.dart';
import 'package:my_life_rpg/views/home/widgets/matrix/session_inspector.dart';
import '../models/quest.dart';

class MatrixController extends GetxController {
  // 依赖注入：直接获取 Service
  final QuestService _questService = Get.find();
  final TimeService _timeService = Get.find();

  // 交互状态
  final selectionStart = RxnInt(); // 第一次点击的格子索引
  final selectionEnd = RxnInt(); // 第二次点击的格子索引

  // 弹窗里的状态
  final RxString selectedQuestId = ''.obs;
  final RxString newQuestTitle = ''.obs;
  final RxBool isCreatingNew = false.obs;

  // 新方法：直接根据 Quest ID 获取颜色类型
  String? getQuestColorType(String questId) {
    final quest = _questService.quests.firstWhereOrNull((q) => q.id == questId);
    if (quest == null) return null;
    return quest.type == QuestType.daemon ? 'cyan' : 'orange';
  }

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

  void _showAddLogDialog(int start, int end) {
    // 1. 计算具体的 DateTime 对象 (基于 selectedDate)
    final date = _timeService.selectedDate.value;
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
    if (_questService.quests.isNotEmpty) {
      selectedQuestId.value = _questService.quests.first.id;
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
                  color: AppColors.accentMain,
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
                  final activeQuests = _questService.quests
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
                      backgroundColor: AppColors.accentMain,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      if (isCreatingNew.value) {
                        // 1. 新建任务
                        if (newQuestTitle.value.trim().isEmpty) return;
                        _questService.addNewQuest(
                          title: newQuestTitle.value,
                          type: QuestType.mission,
                        ); // 没法拿到返回值ID，这是个小问题
                        // 临时解法：addNewQuest 改为返回 Quest 对象，或者获取 quests.last
                        final newQ = _questService.quests.last;
                        _questService.manualAllocate(
                          newQ.id,
                          startTime,
                          endTime,
                        );
                      } else {
                        // 2. 使用现有任务
                        if (selectedQuestId.value.isEmpty) return;
                        _questService.manualAllocate(
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
