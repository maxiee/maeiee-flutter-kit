import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';
import 'package:my_life_rpg/services/task_service.dart';
import '../../../models/project.dart';
import '../../../models/task.dart';

class QuestEditor extends StatefulWidget {
  final Task? quest; // 编辑时传入
  final TaskType? type;

  const QuestEditor({super.key, this.type, this.quest});

  @override
  State<QuestEditor> createState() => _QuestEditorState();
}

class _QuestEditorState extends State<QuestEditor> {
  final TaskService q = Get.find();

  late TextEditingController titleController;
  late TextEditingController subTaskController;
  late TaskType activeType;

  // 表单状态
  Project? selectedProject;
  int intervalDays = 7; // 默认周期

  DateTime? selectedDeadline;
  bool isAllDay = true;

  List<SubTask> checklist = [];

  @override
  void initState() {
    super.initState();

    subTaskController = TextEditingController();

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

      // [关键] 深拷贝 list，避免直接修改原始对象的引用
      // SubTask 虽然是对象，但我们暂时只修改其属性或增删列表，
      // 为了安全，这里重新构建 List。如果 SubTask 也是不可变的，需要 copyWith。
      // 这里假设 SubTask 是可变的 (Models 里的定义)，直接 List.from 即可
      checklist = List.from(existing.checklist);
    } else {
      // 新建模式
      activeType = widget.type ?? TaskType.todo;
      titleController = TextEditingController();
      // 默认值
      intervalDays = 1; // Daemon 默认 Daily
      checklist = [];
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    subTaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.quest != null;
    final isDaemon = widget.type == TaskType.routine;
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
      // 新建模式：使用 SingleChildScrollView 自动适应内容高度
      // 如果内容过多，也需要限制最大高度，防止把按钮顶出屏幕
      content = SingleChildScrollView(
        child: _buildConfigForm(context, color, isEdit),
      );
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

            Expanded(
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
    final isDaemon = activeType == TaskType.routine;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 左侧列 (Left Column): 核心定义与时间 (Identity & Time) ---
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 任务名称
              RpgInput(
                controller: titleController,
                label: isDaemon
                    ? "DAEMON NAME"
                    : "MISSION OBJECTIVE", // 稍微赛博一点的文案
                accentColor: color,
                autofocus: !isEdit, // 新建时自动聚焦
              ),

              AppSpacing.gapV24,

              // 2. 截止时间 / 提醒
              _buildDeadlineSelector(color),
            ],
          ),
        ),
        AppSpacing.gapH24, // 中间分割间距
        // --- 右侧列 (Right Column): 上下文与细节 (Context & Details) ---
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3. 项目归属 或 循环周期
              if (!isDaemon) ...[
                RpgSelect<Project>(
                  label: "PROJECT PROTOCOL:",
                  value: selectedProject,
                  hint: "STANDALONE (无项目)",
                  items: [
                    const DropdownMenuItem<Project>(
                      value: null,
                      child: Text(
                        "STANDALONE (无项目)",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    ...q.projects.map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          p.title,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => selectedProject = val),
                ),
              ] else ...[
                // Daemon Interval
                const RpgText.caption("RECURRENCE CYCLE:"),
                AppSpacing.gapV8,
                Row(
                  children: [
                    _buildIntervalChip(1, "DAILY"),
                    AppSpacing.gapH8,
                    _buildIntervalChip(7, "WEEKLY"),
                    AppSpacing.gapH8,
                    _buildIntervalChip(30, "MONTHLY"),
                  ],
                ),
              ],

              // 4. 子任务 (Tactical Breakdown) - 仅 Todo 显示
              if (!isDaemon) ...[
                AppSpacing.gapV24,
                _buildChecklistSection(color),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistSection(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const RpgText.caption("TACTICAL BREAKDOWN"),
            if (checklist.isNotEmpty)
              RpgText.micro(
                "${checklist.where((e) => e.isCompleted).length}/${checklist.length}",
                color: color,
              ),
          ],
        ),
        AppSpacing.gapV8,

        // 输入行
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36, // 紧凑一点
                child: TextField(
                  controller: subTaskController,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: "Add sub-routine...",
                    hintStyle: AppTextStyles.body.copyWith(
                      color: Colors.white24,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  // 回车提交
                  onSubmitted: (_) => _addSubTask(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _addSubTask,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Icon(Icons.add, color: color, size: 18),
              ),
            ),
          ],
        ),

        AppSpacing.gapV8,

        // 列表展示
        if (checklist.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderDim),
              borderRadius: BorderRadius.circular(4),
              color: Colors.black26,
            ),
            child: Column(
              children: List.generate(checklist.length, (index) {
                final item = checklist[index];
                return _buildSubTaskItem(item, index, color);
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildSubTaskItem(SubTask item, int index, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            item.isCompleted = !item.isCompleted;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // 状态框
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: item.isCompleted
                      ? color.withOpacity(0.5)
                      : Colors.transparent,
                  border: Border.all(
                    color: item.isCompleted ? color : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: item.isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.black)
                    : null,
              ),
              const SizedBox(width: 10),
              // 内容
              Expanded(
                child: Text(
                  item.title,
                  style: AppTextStyles.body.copyWith(
                    color: item.isCompleted ? Colors.grey : Colors.white,
                    decoration: item.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              // 删除
              InkWell(
                onTap: () {
                  setState(() {
                    checklist.removeAt(index);
                  });
                },
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addSubTask() {
    final text = subTaskController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      checklist.add(SubTask(title: text));
      subTaskController.clear();
    });
    // 保持焦点，方便连续输入
    // FocusScope.of(context).requestFocus(); // TextField 默认会保持焦点，不需要额外操作
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
            _deadlineToggleBtn(color),

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

  Widget _deadlineToggleBtn(Color color) {
    return InkWell(
      onTap: () async {
        if (selectedDeadline == null) {
          final now = DateTime.now();
          setState(
            () => selectedDeadline = DateTime(now.year, now.month, now.day + 1),
          );
        } else {
          setState(() => selectedDeadline = null);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: selectedDeadline != null ? color : Colors.grey,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          selectedDeadline != null ? "ACTIVE" : "DISABLED",
          style: TextStyle(
            color: selectedDeadline != null ? color : Colors.grey,
            fontSize: 12,
          ),
        ),
      ),
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
      q.updateTask(
        widget.quest!.id,
        title: title,
        project: selectedProject,
        deadline: selectedDeadline,
        isAllDayDeadline: isAllDay,
        interval: activeType == TaskType.routine ? intervalDays : 0,
        checklist: checklist,
      );
    }
    // 如果是新建模式
    else {
      q.addNewTask(
        title: title,
        type: activeType,
        project: selectedProject,
        interval: activeType == TaskType.routine ? intervalDays : 0,
        deadline: selectedDeadline,
        isAllDayDeadline: isAllDay,
        checklist: checklist,
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
        q.deleteTask(widget.quest!.id);
        Get.back(); // Close Confirm
        Get.back(); // Close Editor
      },
    );
  }
}
