import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/rpg_tab_bar.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import 'package:my_life_rpg/services/task_service.dart';
import 'package:my_life_rpg/models/task.dart';

class TimeAllocationDialog extends StatefulWidget {
  final DateTime startTime;
  final DateTime endTime;
  final TaskService questService;

  const TimeAllocationDialog({
    super.key,
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

  // 内部时间状态
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    // 初始化时间状态
    _start = widget.startTime;
    _end = widget.endTime;

    // 过滤活跃任务
    activeQuests = widget.questService.tasks
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
          // 可编辑的时间区域
          _buildTimeEditor(),

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

  // 时间编辑器组件
  Widget _buildTimeEditor() {
    return Row(
      children: [
        Expanded(
          child: _buildTimeButton(
            label: "START TIME",
            time: _start,
            onTap: () => _pickTime(true),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.arrow_forward, color: AppColors.textDim, size: 16),
        ),
        Expanded(
          child: _buildTimeButton(
            label: "END TIME",
            time: _end,
            onTap: () => _pickTime(false),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeButton({
    required String label,
    required DateTime time,
    required VoidCallback onTap,
  }) {
    final timeStr = DateFormat('HH:mm').format(time);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.bgInput,
          border: Border.all(color: AppColors.accentMain.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.micro.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentMain,
                  ),
                ),
                const Icon(Icons.edit, size: 12, color: AppColors.textDim),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 时间选择逻辑
  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
    );

    if (picked != null) {
      setState(() {
        // 只更新时分，保留年月日
        final newDt = DateTime(
          initial.year,
          initial.month,
          initial.day,
          picked.hour,
          picked.minute,
        );

        if (isStart) {
          _start = newDt;
          // 简单的自动纠错：如果开始时间晚于结束时间，把结束时间往后推 15分钟
          if (_start.isAfter(_end)) {
            _end = _start.add(const Duration(minutes: 15));
          }
        } else {
          _end = newDt;
          // 简单的自动纠错
          if (_end.isBefore(_start)) {
            _start = _end.subtract(const Duration(minutes: 15));
          }
        }
      });
    }
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
    // 基础校验
    if (_start.isAfter(_end)) {
      Get.snackbar("ERROR", "End time must be after start time");
      return;
    }

    final data = {
      // [关键] 返回修正后的时间
      'startTime': _start,
      'endTime': _end,
      'isNew': isCreatingNew,
    };

    if (isCreatingNew) {
      final title = _titleController.text.trim();
      if (title.isEmpty) return;
      data['title'] = title;
    } else {
      if (selectedQuestId.isEmpty) return;
      data['id'] = selectedQuestId;
    }

    Get.back(result: data);
  }
}
