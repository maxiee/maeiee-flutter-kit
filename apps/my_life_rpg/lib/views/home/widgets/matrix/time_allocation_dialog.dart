import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import 'package:my_life_rpg/models/quest.dart';

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
  late List<Quest> activeQuests;

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
    return Dialog(
      backgroundColor: AppColors.bgPanel,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        side: const BorderSide(color: AppColors.borderDim),
      ),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              "ALLOCATE TIME SEGMENT",
              style: AppTextStyles.panelHeader.copyWith(
                color: AppColors.accentMain,
              ),
            ),
            AppSpacing.gapV8,
            Text(
              widget.timeRangeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Courier',
              ),
            ),
            AppSpacing.gapV20,

            // Tabs
            Row(
              children: [
                _buildTab("EXISTING QUEST", !isCreatingNew, false),
                AppSpacing.gapH16,
                _buildTab("CREATE NEW", isCreatingNew, true),
              ],
            ),
            AppSpacing.gapV16,

            // Content Area
            SizedBox(
              height: 60, // 固定高度防止跳动
              child: isCreatingNew
                  ? _buildCreateInput()
                  : _buildSelectDropdown(),
            ),

            AppSpacing.gapV24,

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                RpgButton(
                  label: "CANCEL",
                  type: RpgButtonType.ghost,
                  onTap: () => Get.back(), // 传回 null 表示取消
                ),
                AppSpacing.gapH12,
                RpgButton(label: "CONFIRM", onTap: _submit),
              ],
            ),
          ],
        ),
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

    return Container(
      padding: AppSpacing.paddingHorizontalMd,
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.borderDim),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: activeQuests.any((q) => q.id == selectedQuestId)
              ? selectedQuestId
              : null,
          dropdownColor: AppColors.bgCard,
          isExpanded: true,
          style: AppTextStyles.body,
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
        ),
      ),
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
