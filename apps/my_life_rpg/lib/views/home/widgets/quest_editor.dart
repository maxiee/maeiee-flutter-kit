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

  const QuestEditor({super.key, this.type, this.quest});

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

    // 动态计算标题
    String title;
    if (isEdit) {
      title = isDaemon ? "编辑习惯" : "编辑待办";
    } else {
      title = isDaemon ? "新建习惯" : "新建待办";
    }

    // 构建核心内容
    Widget content;
    if (!isEdit) {
      // 新建模式：直接显示配置表单
      content = _buildConfigForm(context, color, isEdit);
    } else {
      // 编辑模式：包含 TabView
      content = DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.black26,
              child: TabBar(
                indicatorColor: color,
                labelColor: color,
                unselectedLabelColor: Colors.grey,
                labelStyle: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(text: "配置"),
                  Tab(text: "历史记录"),
                ],
              ),
            ),
            SizedBox(
              height: 350, // 限制高度，允许内部滚动
              child: TabBarView(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 16), // Tab 和内容的间距
                    child: _buildConfigForm(context, color, isEdit),
                  ),
                  _buildHistoryTab(context, color),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RpgDialog(
      title: title,
      icon: isDaemon ? Icons.loop : Icons.code,
      accentColor: color,
      onCancel: () => Get.back(),
      actions: [
        if (isEdit)
          TextButton(
            onPressed: _delete,
            child: const Text(
              "删除",
              style: TextStyle(color: AppColors.accentDanger),
            ),
          ),
        if (isEdit) AppSpacing.gapH12,

        RpgButton(
          label: isEdit ? "保存" : "创建",
          type: isDaemon ? RpgButtonType.secondary : RpgButtonType.primary,
          onTap: _submit,
        ),
      ],
      child: content,
    );
  }

  Widget _buildConfigForm(BuildContext context, Color color, bool isEdit) {
    final isDaemon = activeType == QuestType.daemon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RpgInput(
          controller: titleController,
          label: "任务名称",
          accentColor: color,
          autofocus: !isEdit,
        ),
        AppSpacing.gapV16,
        _buildDeadlineSelector(color),
        AppSpacing.gapV16,

        if (!isDaemon) ...[
          // [REFACTORED] Mission: Project Selector
          RpgSelect<Project>(
            label: "所属项目:",
            value: selectedProject,
            hint: "无项目 (Standalone)",
            items: [
              const DropdownMenuItem<Project>(
                value: null,
                child: Text("无项目 (Standalone)", style: TextStyle(fontSize: 12)),
              ),
              ...q.projects.map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text(p.title, style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
            onChanged: (val) => setState(() => selectedProject = val),
          ),
        ] else ...[
          // Daemon Interval 保持原样或后续优化
          const RpgText.caption("重复周期:"),
          AppSpacing.gapV8,
          Row(
            children: [
              _buildIntervalChip(1, "每天"),
              AppSpacing.gapH8,
              _buildIntervalChip(7, "每周"),
              AppSpacing.gapH8,
              _buildIntervalChip(30, "每月"),
            ],
          ),
        ],
      ],
    );
  }

  // --- TAB 2: History (新增) ---
  Widget _buildHistoryTab(BuildContext context, Color color) {
    // 实时获取最新的 quest 数据 (因为可能会删除 session)
    // 注意：widget.quest 是 final 的，但其内部 sessions 列表是可变的引用。
    // 为了安全，我们最好从 Service 里 find 一下，或者 wrap Obx

    // 简单起见，直接用 widget.quest.sessions，因为删除是在 Service 层操作内存对象
    final sessions = widget.quest!.sessions;
    // 按时间倒序
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    if (sessions.isEmpty) {
      return const Center(child: RpgEmptyState(message: "暂无记录"));
    }

    return Column(
      children: [
        // Stats Summary
        RpgContainer(
          style: RpgContainerStyle.card,
          overrideColor: color,
          margin: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              RpgStat(
                label: "总时长",
                value: (widget.quest!.totalDurationSeconds / 3600)
                    .toStringAsFixed(1),
                unit: "h",
                compact: true,
              ),
              RpgStat(label: "次数", value: "${sessions.length}", compact: true),
              RpgStat(
                label: "平均",
                value: sessions.isNotEmpty
                    ? (widget.quest!.totalDurationSeconds /
                              sessions.length /
                              60)
                          .toStringAsFixed(0)
                    : "0",
                unit: "m",
                compact: true,
              ),
            ],
          ),
        ),

        const RpgDivider(),

        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final s = sessions[i];
              final dateStr = DateFormat('yyyy-MM-dd').format(s.startTime);
              final timeStr =
                  "${DateFormat('HH:mm').format(s.startTime)} - ${s.endTime != null ? DateFormat('HH:mm').format(s.endTime!) : 'NOW'}";
              final durationStr =
                  "${(s.durationSeconds / 60).toStringAsFixed(0)}m";

              return RpgContainer(
                style: RpgContainerStyle.panel,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: AppTextStyles.micro.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Duration
                    Text(
                      durationStr,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Delete Action
                    InkWell(
                      onTap: () => _deleteSession(s.id),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _deleteSession(String sessionId) {
    // 调用 Service 删除
    q.deleteSession(widget.quest!.id, sessionId);
    // 强制刷新 UI (因为 sessions 是引用，Service 里的 refresh 可能不会触发 State 的 build)
    setState(() {});
  }

  Widget _buildDeadlineSelector(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "截止时间 (Deadline):",
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
                      selectedDeadline == null ? "无截止" : "已启用",
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
                    isAllDay ? "全天" : "精确",
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
        "确定要删除此任务及其历史记录吗？\n(已获得的经验会保留)",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      ),
      backgroundColor: AppColors.bgPanel,
      confirmTextColor: Colors.white,
      textConfirm: "删除",
      textCancel: "取消",
      buttonColor: AppColors.accentDanger,
      onConfirm: () {
        q.deleteQuest(widget.quest!.id);
        Get.back(); // Close Confirm
        Get.back(); // Close Editor
      },
    );
  }
}
