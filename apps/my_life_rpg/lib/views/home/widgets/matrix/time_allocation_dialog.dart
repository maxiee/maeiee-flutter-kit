import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/rpg_tab_bar.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import 'package:my_life_rpg/models/task.dart';

class TimeAllocationDialog extends StatefulWidget {
  final String timeRangeText;
  final DateTime startTime;
  final DateTime endTime;
  final QuestService questService;

  const TimeAllocationDialog({
    super.key,
    required this.timeRangeText,
    required this.startTime,
    required this.endTime,
    required this.questService,
  });

  @override
  State<TimeAllocationDialog> createState() => _TimeAllocationDialogState();
}

class _TimeAllocationDialogState extends State<TimeAllocationDialog> {
  // 状态
  bool isCreatingNew = false;
  String selectedQuestId = '';
  final TextEditingController _titleController = TextEditingController();

  // 数据源
  late List<Task> activeQuests;

  @override
  void initState() {
    super.initState();
    // 过滤活跃任务
    activeQuests = widget.questService.quests
        .where((q) => !q.isCompleted)
        .toList();

    // 默认选中第一个
    if (activeQuests.isNotEmpty) {
      selectedQuestId = activeQuests.first.id;
    } else {
      // 如果没有活跃任务，强制切换到创建模式
      isCreatingNew = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RpgDialog(
      title: "ALLOCATE TIME SEGMENT",
      icon: Icons.access_time,
      onCancel: () => Get.back(),
      actions: [RpgButton(label: "CONFIRM", onTap: _submit)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-header (Time)
          RpgText.header(widget.timeRangeText),
          AppSpacing.gapV20,

          // Tabs
          RpgTabBar(
            tabs: const ["EXISTING QUEST", "CREATE NEW"],
            selectedIndex: isCreatingNew ? 1 : 0,
            onTabSelected: (index) =>
                setState(() => isCreatingNew = index == 1),
          ),
          AppSpacing.gapV16,

          // Content
          SizedBox(
            height: 60,
            child: isCreatingNew ? _buildCreateInput() : _buildSelectDropdown(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive, bool mode) {
    return InkWell(
      onTap: () {
        setState(() => isCreatingNew = mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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

  Widget _buildCreateInput() {
    return RpgInput(
      controller: _titleController,
      label: "NEW QUEST TITLE",
      autofocus: true, // 自动聚焦
    );
  }

  Widget _buildSelectDropdown() {
    if (activeQuests.isEmpty) {
      return const Center(
        child: Text(
          "NO ACTIVE QUESTS. SWITCH TO CREATE.",
          style: TextStyle(
            color: AppColors.accentDanger,
            fontFamily: 'Courier',
          ),
        ),
      );
    }

    return RpgSelect<String>(
      value: activeQuests.any((q) => q.id == selectedQuestId)
          ? selectedQuestId
          : null,
      items: activeQuests
          .map(
            (q) => DropdownMenuItem(
              value: q.id,
              child: Text(
                q.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => selectedQuestId = val);
      },
    );
  }

  void _submit() {
    // 封装返回数据：Map
    if (isCreatingNew) {
      final title = _titleController.text.trim();
      if (title.isEmpty) return;
      Get.back(result: {'isNew': true, 'title': title});
    } else {
      if (selectedQuestId.isEmpty) return;
      Get.back(result: {'isNew': false, 'id': selectedQuestId});
    }
  }
}
