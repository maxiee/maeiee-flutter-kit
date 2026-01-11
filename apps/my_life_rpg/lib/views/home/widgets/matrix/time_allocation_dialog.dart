import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_life_rpg/models/project.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';
import 'package:rpg_cyber_ui/widgets/rpg_tab_bar.dart';
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
  // 0=Task, 1=Project, 2=System
  int selectedMode = 0;
  String? selectedId; // 可能是 TaskId, ProjectId 或 CategoryName

  // 仅用于 Task 模式下的新建功能
  final TextEditingController _newTitleCtrl = TextEditingController();
  bool isCreatingNewTask = false;

  // 数据缓存
  late List<Task> activeQuests;
  late List<Project> activeProjects;

  // 预置的系统类别
  final List<String> systemCategories = ["休息", "深度工作", "噪声", "自我梳理", "学习"];

  // 时间状态
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
    activeProjects = widget.questService.projects;

    // 默认选中
    if (activeQuests.isNotEmpty) {
      selectedId = activeQuests.first.id;
    } else if (activeProjects.isNotEmpty) {
      selectedMode = 1; // 没任务就切到项目
      selectedId = activeProjects.first.id;
    } else {
      selectedMode = 2; // 啥都没就切到系统
      selectedId = systemCategories.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RpgDialog(
      title: "LOG TIME SEGMENT",
      icon: Icons.history_edu,
      onCancel: () => Get.back(),
      actions: [RpgButton(label: "CONFIRM LOG", onTap: _submit)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 时间编辑器
          _buildTimeEditor(),

          AppSpacing.gapV20,

          // 2. 模式切换 Tabs
          RpgTabBar(
            tabs: const ["TASK", "PROJECT", "SYSTEM"],
            selectedIndex: selectedMode,
            onTabSelected: (index) {
              setState(() {
                selectedMode = index;
                isCreatingNewTask = false; // 重置新建状态
                // 切换后重置默认选中项
                if (index == 0 && activeQuests.isNotEmpty) {
                  selectedId = activeQuests.first.id;
                }
                if (index == 1 && activeProjects.isNotEmpty) {
                  selectedId = activeProjects.first.id;
                }
                if (index == 2) selectedId = systemCategories.first;
              });
            },
          ),
          AppSpacing.gapV16,

          // 3. 动态内容区
          SizedBox(height: 60, child: _buildSelectorBody()),
        ],
      ),
    );
  }

  Widget _buildSelectorBody() {
    // Mode 0: Task (Existing OR New)
    if (selectedMode == 0) {
      if (isCreatingNewTask) {
        return Row(
          children: [
            Expanded(
              child: RpgInput(
                controller: _newTitleCtrl,
                hint: "New task title...",
                autofocus: true,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => setState(() => isCreatingNewTask = false),
            ),
          ],
        );
      }

      if (activeQuests.isEmpty) {
        return Center(
          child: TextButton.icon(
            icon: const Icon(Icons.add, color: AppColors.accentMain),
            label: const Text(
              "Create New Task",
              style: TextStyle(color: AppColors.accentMain),
            ),
            onPressed: () => setState(() => isCreatingNewTask = true),
          ),
        );
      }

      return Row(
        children: [
          Expanded(
            child: RpgSelect<String>(
              value: activeQuests.any((q) => q.id == selectedId)
                  ? selectedId
                  : null,
              items: activeQuests
                  .map(
                    (q) => DropdownMenuItem(
                      value: q.id,
                      child: Text(q.title, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => selectedId = val),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: "Create New instead",
            child: InkWell(
              onTap: () => setState(() => isCreatingNewTask = true),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.add, color: Colors.white54),
              ),
            ),
          ),
        ],
      );
    }

    // Mode 1: Project (Direct Log)
    if (selectedMode == 1) {
      if (activeProjects.isEmpty) {
        return const Center(
          child: Text(
            "NO PROJECTS DEFINED",
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      return RpgSelect<String>(
        value: activeProjects.any((p) => p.id == selectedId)
            ? selectedId
            : null,
        items: activeProjects
            .map(
              (p) => DropdownMenuItem(
                value: p.id,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      color: p.color,
                      margin: const EdgeInsets.only(right: 8),
                    ),
                    Text(p.title),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (val) => setState(() => selectedId = val),
      );
    }

    // Mode 2: System (Category)
    if (selectedMode == 2) {
      // 使用 Wrap 或者简单的 Select，这里用 Select 保持一致
      return RpgSelect<String>(
        value: selectedId,
        items: systemCategories
            .map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text(
                  c,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (val) => setState(() => selectedId = val),
      );
    }

    return const SizedBox.shrink();
  }

  // 时间编辑器组件
  Widget _buildTimeEditor() {
    return Row(
      children: [
        Expanded(
          child: _buildTimeButton(
            label: "START",
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
            label: "END",
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

  void _submit() {
    // 基础校验
    if (_start.isAfter(_end)) {
      Get.snackbar(
        "ERROR",
        "Time logic failure.",
        backgroundColor: Colors.black,
        colorText: Colors.red,
      );
      return;
    }

    if (selectedId == null && !isCreatingNewTask) return;

    // 调用 Service 的新接口
    final result = widget.questService.quickAllocate(
      targetId: selectedId ?? "", //
      mode: isCreatingNewTask ? 0 : selectedMode,
      customTitle: isCreatingNewTask ? _newTitleCtrl.text.trim() : null,
      start: _start,
      end: _end,
    );

    if (result.isSuccess) {
      Get.back(result: {'success': true}); // 只需要告诉 Controller 成功了，不需要回传复杂 Map
    } else {
      Get.snackbar(
        "FAIL",
        result.errorMessage ?? "Unknown Error",
        backgroundColor: Colors.black,
        colorText: Colors.red,
      );
    }
  }
}
