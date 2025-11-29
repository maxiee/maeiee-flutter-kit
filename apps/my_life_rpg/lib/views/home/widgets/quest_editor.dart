import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import '../../../models/project.dart';
import '../../../models/quest.dart';

class QuestEditor extends StatefulWidget {
  final QuestType type;

  const QuestEditor({Key? key, required this.type}) : super(key: key);

  @override
  State<QuestEditor> createState() => _QuestEditorState();
}

class _QuestEditorState extends State<QuestEditor> {
  final QuestService q = Get.find();
  final titleController = TextEditingController();

  // 表单状态
  Project? selectedProject;
  int intervalDays = 7; // 默认周期

  DateTime? selectedDeadline;
  bool isAllDay = true;

  @override
  Widget build(BuildContext context) {
    final isDaemon = widget.type == QuestType.daemon;
    final color = isDaemon ? Colors.cyanAccent : Colors.orangeAccent;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  isDaemon ? "INITIALIZE DAEMON" : "DEPLOY MISSION",
                  style: TextStyle(
                    color: color,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Title Input
            TextField(
              controller: titleController,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Courier',
              ),
              decoration: InputDecoration(
                labelText: "IDENTIFIER (TITLE)",
                labelStyle: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Courier',
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: color),
                ),
                filled: true,
                fillColor: Colors.black38,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // 在 Title Input 下方插入
            _buildDeadlineSelector(color),
            const SizedBox(height: 16),

            // 2. Context Selectors
            if (!isDaemon) ...[
              // Mission 模式：选择 Project
              const Text(
                "LINK TO CAMPAIGN (OPTIONAL):",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontFamily: 'Courier',
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Project>(
                    value: selectedProject,
                    dropdownColor: const Color(0xFF252525),
                    isExpanded: true,
                    hint: const Text(
                      "STANDALONE (无归属)",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontFamily: 'Courier',
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                    items: [
                      const DropdownMenuItem<Project>(
                        value: null,
                        child: Text("STANDALONE (无归属)"),
                      ),
                      ...q.projects.map(
                        (p) => DropdownMenuItem(value: p, child: Text(p.title)),
                      ),
                    ],
                    onChanged: (val) => setState(() => selectedProject = val),
                  ),
                ),
              ),
            ] else ...[
              // Daemon 模式：选择周期
              const Text(
                "EXECUTION INTERVAL (DAYS):",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontFamily: 'Courier',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildIntervalChip(1, "DAILY"),
                  const SizedBox(width: 8),
                  _buildIntervalChip(7, "WEEKLY"),
                  const SizedBox(width: 8),
                  _buildIntervalChip(21, "3-WEEKS"),
                  const SizedBox(width: 8),
                  _buildIntervalChip(30, "MONTHLY"),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // 3. Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    "ABORT",
                    style: TextStyle(color: Colors.grey, fontFamily: 'Courier'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withOpacity(0.2),
                    foregroundColor: color,
                    side: BorderSide(color: color),
                  ),
                  onPressed: _submit,
                  child: const Text(
                    "EXECUTE",
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
    );
  }

  Widget _buildDeadlineSelector(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "TEMPORAL ANCHOR (DEADLINE):",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontFamily: 'Courier',
          ),
        ),
        const SizedBox(height: 8),
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selectedDeadline != null
                      ? color.withOpacity(0.2)
                      : Colors.transparent,
                  border: Border.all(
                    color: selectedDeadline != null ? color : Colors.white24,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_off_outlined,
                      size: 16,
                      color: selectedDeadline != null ? color : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedDeadline == null ? "NO DEADLINE" : "ACTIVE",
                      style: TextStyle(
                        color: selectedDeadline != null ? color : Colors.grey,
                        fontSize: 12,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

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

              const SizedBox(width: 8),

              // 全天/时间切换
              InkWell(
                onTap: () => setState(() => isAllDay = !isAllDay),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isAllDay ? "ALL DAY" : "PRECISE",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(4),
          color: Colors.black38,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontFamily: 'Courier',
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.cyanAccent : Colors.transparent,
            border: Border.all(color: Colors.cyanAccent),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            "$days",
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final title = titleController.text.trim();
    if (title.isEmpty) return;

    // 调用 Controller 添加逻辑
    q.addNewQuest(
      title: title,
      type: widget.type,
      project: selectedProject,
      interval: widget.type == QuestType.daemon ? intervalDays : 0,
      deadline: selectedDeadline,
      isAllDayDeadline: isAllDay,
    );

    Get.back();
  }
}
