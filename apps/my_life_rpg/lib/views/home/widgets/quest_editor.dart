import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import '../../../models/project.dart';
import '../../../models/quest.dart';

class QuestEditor extends StatefulWidget {
  final Quest? quest; // 编辑时传入
  final QuestType? type;

  const QuestEditor({Key? key, this.type, this.quest}) : super(key: key);

  @override
  State<QuestEditor> createState() => _QuestEditorState();
}

class _QuestEditorState extends State<QuestEditor> {
  final QuestService q = Get.find();

  late TextEditingController titleController;
  late QuestType activeType;

  // 表单状态
  Project? selectedProject;
  int intervalDays = 7; // 默认周期

  DateTime? selectedDeadline;
  bool isAllDay = true;

  @override
  void initState() {
    super.initState();

    // 1. 确定模式 (编辑 vs 新建)
    if (widget.quest != null) {
      // 编辑模式：回填数据
      final existing = widget.quest!;
      activeType = existing.type;
      titleController = TextEditingController(text: existing.title);

      // 回填 Project
      if (existing.projectId != null) {
        selectedProject = q.projects.firstWhereOrNull(
          (p) => p.id == existing.projectId,
        );
      }

      // 回填 Deadline
      selectedDeadline = existing.deadline;
      isAllDay = existing.isAllDayDeadline;

      // 回填 Interval
      intervalDays = existing.intervalDays > 0 ? existing.intervalDays : 7;
    } else {
      // 新建模式
      activeType = widget.type ?? QuestType.mission;
      titleController = TextEditingController();
      // 默认值
      intervalDays = 1; // Daemon 默认 Daily
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.quest != null;
    final isDaemon = widget.type == QuestType.daemon;
    final color = isDaemon ? AppColors.accentSystem : AppColors.accentMain;

    return Dialog(
      backgroundColor: AppColors.bgPanel,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      // 防止键盘遮挡
      child: SingleChildScrollView(
        child: Padding(
          padding: AppSpacing.paddingLg + AppSpacing.paddingXs,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    isDaemon ? Icons.loop : Icons.code,
                    color: color,
                    size: AppSpacing.iconLg,
                  ),
                  AppSpacing.gapH12,
                  Text(
                    isEdit
                        ? (isDaemon ? "CONFIGURE DAEMON" : "CONFIGURE MISSION")
                        : (isDaemon ? "INITIALIZE DAEMON" : "DEPLOY MISSION"),
                    style: AppTextStyles.panelHeader.copyWith(
                      color: color,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapV20,

              // 1. Title Input
              RpgInput(
                controller: titleController,
                label: "IDENTIFIER (TITLE)",
                accentColor: color,
                autofocus: !isEdit, // 编辑时不自动聚焦，防止弹键盘遮挡
              ),
              AppSpacing.gapV16,

              // 在 Title Input 下方插入
              _buildDeadlineSelector(color),
              AppSpacing.gapV16,

              // 2. Context Selectors
              if (!isDaemon) ...[
                // Mission 模式：选择 Project
                Text(
                  "LINK TO CAMPAIGN (OPTIONAL):",
                  style: AppTextStyles.caption.copyWith(color: Colors.grey),
                ),
                AppSpacing.gapV8,
                Container(
                  padding: AppSpacing.paddingHorizontalMd,
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(color: AppColors.borderDim),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Project>(
                      value: selectedProject,
                      dropdownColor: AppColors.bgCard,
                      isExpanded: true,
                      hint: Text(
                        "STANDALONE (无归属)",
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textDim,
                          fontSize: 12,
                        ),
                      ),
                      style: AppTextStyles.body.copyWith(fontSize: 12),
                      items: [
                        DropdownMenuItem<Project>(
                          value: null,
                          child: Text(
                            "STANDALONE (无归属)",
                            style: AppTextStyles.body.copyWith(fontSize: 12),
                          ),
                        ),
                        ...q.projects.map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p.title,
                              style: AppTextStyles.body.copyWith(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) => setState(() => selectedProject = val),
                    ),
                  ),
                ),
              ] else ...[
                // Daemon 模式：选择周期
                Text(
                  "EXECUTION INTERVAL (DAYS):",
                  style: AppTextStyles.caption.copyWith(color: Colors.grey),
                ),
                AppSpacing.gapV8,
                Row(
                  children: [
                    _buildIntervalChip(1, "DAILY"),
                    AppSpacing.gapH8,
                    _buildIntervalChip(7, "WEEKLY"),
                    AppSpacing.gapH8,
                    _buildIntervalChip(21, "3-WEEKS"),
                    AppSpacing.gapH8,
                    _buildIntervalChip(30, "MONTHLY"),
                  ],
                ),
              ],

              AppSpacing.gapV24,

              // 3. Actions
              Row(
                children: [
                  // DELETE BUTTON (Only in Edit Mode)
                  if (isEdit)
                    TextButton(
                      onPressed: _delete,
                      child: const Text(
                        "DELETE",
                        style: TextStyle(color: AppColors.accentDanger),
                      ),
                    ),

                  const Spacer(),
                  RpgButton(
                    label: "ABORT",
                    type: RpgButtonType.ghost,
                    onTap: () => Get.back(),
                  ),
                  AppSpacing.gapH8,
                  RpgButton(
                    label: "EXECUTE",
                    type: isDaemon
                        ? RpgButtonType.secondary
                        : RpgButtonType.primary,
                    onTap: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeadlineSelector(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "TEMPORAL ANCHOR (DEADLINE):",
          style: AppTextStyles.caption.copyWith(color: Colors.grey),
        ),
        AppSpacing.gapV8,
        Row(
          children: [
            // 开关
            InkWell(
              onTap: () async {
                if (selectedDeadline == null) {
                  // 首次点击，默认选明天
                  final now = DateTime.now();
                  setState(
                    () => selectedDeadline = DateTime(
                      now.year,
                      now.month,
                      now.day + 1,
                    ),
                  );
                } else {
                  // 取消
                  setState(() => selectedDeadline = null);
                }
              },
              borderRadius: AppSpacing.borderRadiusMd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: selectedDeadline != null
                      ? color.withOpacity(0.2)
                      : Colors.transparent,
                  border: Border.all(
                    color: selectedDeadline != null
                        ? color
                        : AppColors.borderBright,
                  ),
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_off_outlined,
                      size: AppSpacing.iconMd - 2,
                      color: selectedDeadline != null ? color : Colors.grey,
                    ),
                    AppSpacing.gapH8,
                    Text(
                      selectedDeadline == null ? "NO DEADLINE" : "ACTIVE",
                      style: AppTextStyles.body.copyWith(
                        color: selectedDeadline != null ? color : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            AppSpacing.gapH12,

            // 如果激活了，显示日期/时间选择
            if (selectedDeadline != null) ...[
              // 日期选择
              _buildPickerChip(
                DateFormat('MM-dd').format(selectedDeadline!),
                color,
                () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDeadline!,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) =>
                        Theme(data: ThemeData.dark(), child: child!),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDeadline = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        selectedDeadline!.hour,
                        selectedDeadline!.minute,
                      );
                    });
                  }
                },
              ),

              AppSpacing.gapH8,

              // 全天/时间切换
              InkWell(
                onTap: () => setState(() => isAllDay = !isAllDay),
                borderRadius: AppSpacing.borderRadiusMd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderBright),
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                  child: Text(
                    isAllDay ? "ALL DAY" : "PRECISE",
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              AppSpacing.gapH8,

              // 时间选择 (仅当 !isAllDay)
              if (!isAllDay)
                _buildPickerChip(
                  DateFormat('HH:mm').format(selectedDeadline!),
                  color,
                  () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDeadline!),
                      builder: (context, child) =>
                          Theme(data: ThemeData.dark(), child: child!),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDeadline = DateTime(
                          selectedDeadline!.year,
                          selectedDeadline!.month,
                          selectedDeadline!.day,
                          picked.hour,
                          picked.minute,
                        );
                      });
                    }
                  },
                ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPickerChip(String text, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderBright),
          borderRadius: AppSpacing.borderRadiusMd,
          color: AppColors.bgInput,
        ),
        child: Text(
          text,
          style: AppTextStyles.body.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildIntervalChip(int days, String label) {
    final isSelected = intervalDays == days;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => intervalDays = days),
        borderRadius: AppSpacing.borderRadiusMd,
        child: Container(
          padding: AppSpacing.paddingVerticalSm,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentSystem : Colors.transparent,
            border: Border.all(color: AppColors.accentSystem),
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          child: Text(
            "$days",
            style: AppTextStyles.body.copyWith(
              color: isSelected ? Colors.black : AppColors.accentSystem,
              fontWeight: FontWeight.bold,
              fontSize: 12, // 微调字体
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final title = titleController.text.trim();
    if (title.isEmpty) return;

    // 如果是编辑模式
    if (widget.quest != null) {
      q.updateQuest(
        widget.quest!.id,
        title: title,
        project: selectedProject,
        deadline: selectedDeadline,
        isAllDayDeadline: isAllDay,
        interval: activeType == QuestType.daemon ? intervalDays : 0,
      );
    }
    // 如果是新建模式
    else {
      q.addNewQuest(
        title: title,
        type: activeType,
        project: selectedProject,
        interval: activeType == QuestType.daemon ? intervalDays : 0,
        deadline: selectedDeadline,
        isAllDayDeadline: isAllDay,
      );
    }

    Get.back();
  }

  void _delete() {
    if (widget.quest == null) return;

    // 二次确认
    Get.defaultDialog(
      title: "CONFIRM DELETION",
      titleStyle: AppTextStyles.panelHeader.copyWith(
        color: AppColors.accentDanger,
      ),
      content: const Text(
        "Permanently remove this operation and its history?\n(XP will be retained in history, but mission logs will be lost)",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      ),
      backgroundColor: AppColors.bgPanel,
      confirmTextColor: Colors.white,
      textConfirm: "DELETE",
      textCancel: "CANCEL",
      buttonColor: AppColors.accentDanger,
      onConfirm: () {
        q.deleteQuest(widget.quest!.id);
        Get.back(); // Close Confirm
        Get.back(); // Close Editor
      },
    );
  }
}
