import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_life_rpg/core/domain/time_domain.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';
import 'package:my_life_rpg/models/task.dart';
import 'package:my_life_rpg/services/task_service.dart';

class SessionInspector extends StatefulWidget {
  final Task quest;
  final FocusSession session;

  const SessionInspector({
    super.key,
    required this.quest,
    required this.session,
  });

  @override
  State<SessionInspector> createState() => _SessionInspectorState();
}

class _SessionInspectorState extends State<SessionInspector> {
  final TaskService qs = Get.find();
  late DateTime _startTime;
  late DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    // 建立本地状态副本，方便编辑
    _startTime = widget.session.startTime;
    _endTime = widget.session.endTime;
  }

  @override
  Widget build(BuildContext context) {
    // 颜色
    final color = widget.quest.type == TaskType.routine
        ? AppColors.accentSystem
        : AppColors.accentMain;

    final startStr = DateFormat('MM-dd HH:mm').format(_startTime);
    final endStr = _endTime != null
        ? DateFormat('MM-dd HH:mm').format(_endTime!)
        : "ACTIVE NOW";

    // 实时计算时长显示
    final durationSec = (_endTime ?? DateTime.now())
        .difference(_startTime)
        .inSeconds;
    final durationMin = durationSec ~/ 60;

    return RpgDialog(
      title: "SESSION DATA",
      icon: Icons.edit_calendar, // 换个图标表示可编辑
      accentColor: color,
      onCancel: () => Get.back(),
      actions: [
        // 删除按钮
        RpgButton(
          label: "DELETE",
          type: RpgButtonType.danger,
          icon: Icons.delete_forever,
          onTap: _confirmDelete,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 任务信息
          Text(
            widget.quest.title,
            style: AppTextStyles.panelHeader.copyWith(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          if (widget.quest.projectName != null) ...[
            const SizedBox(height: 4),
            RpgTag(label: widget.quest.projectName!, color: color),
          ],

          AppSpacing.gapV20,

          // 2. 可编辑的时间胶囊 (Editable Time Capsule)
          RpgContainer(
            style: RpgContainerStyle.panel,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // START
                InkWell(
                  onTap: () => _pickTime(true),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("START", style: AppTextStyles.micro),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            startStr,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, size: 12, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),

                // END
                InkWell(
                  onTap: () => _pickTime(false),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("END", style: AppTextStyles.micro),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            endStr,
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                              color: _endTime == null
                                  ? AppColors.accentSafe
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (_endTime != null)
                            const Icon(
                              Icons.edit,
                              size: 12,
                              color: Colors.grey,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                Container(width: 1, height: 24, color: Colors.white10),

                // DURATION
                RpgStat(
                  label: "DURATION",
                  value: "${durationMin}m",
                  valueColor: AppColors.accentSafe,
                  compact: true,
                  alignment: CrossAxisAlignment.end,
                ),
              ],
            ),
          ),

          // 3. 日志 (保持不变)
          if (widget.session.logs.isNotEmpty) ...[
            AppSpacing.gapV24,
            const Text("LOGS DATA:", style: AppTextStyles.micro),
            AppSpacing.gapV8,
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.session.logs.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "> ${widget.session.logs[i].content}",
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 核心逻辑：更新时间并保存
  void _updateTime(bool isStart, DateTime newTime) {
    // 1. 基础逻辑校验
    DateTime tempStart = isStart ? newTime : _startTime;
    DateTime tempEnd = !isStart && _endTime != null
        ? newTime
        : (_endTime ?? DateTime.now());

    // 如果结束时间为空（进行中），暂不校验结束边界，只校验开始时间是否晚于当前
    if (_endTime == null && !isStart) {
      // 试图设置结束时间
      tempEnd = newTime;
    }

    if (tempEnd.isBefore(tempStart)) {
      Get.snackbar(
        "ERROR",
        "End time cannot be before Start time",
        backgroundColor: Colors.black,
        colorText: AppColors.accentDanger,
      );
      return;
    }

    // 2. 碰撞检测 (Collision Detection)
    // 必须排除自己当前的 Session ID，否则会和自己冲突
    final allSessions = qs.tasks.expand((q) => q.sessions).toList();
    final hasOverlap = TimeDomain.hasOverlap(
      tempStart,
      tempEnd,
      allSessions,
      excludeSessionId: widget.session.id, // 排除自己
    );

    if (hasOverlap) {
      Get.snackbar(
        "CONFLICT",
        "Time slot overlaps with another record.",
        backgroundColor: Colors.black,
        colorText: AppColors.accentDanger,
      );
      return;
    }

    // 3. 执行更新 (直接修改引用对象)
    setState(() {
      if (isStart) {
        _startTime = newTime;
        widget.session.startTime = newTime; // 修改源对象，因为是引用传递
      } else {
        _endTime = newTime;
        widget.session.endTime = newTime;
      }

      // 重算时长
      final end = _endTime ?? DateTime.now();
      widget.session.durationSeconds = end.difference(_startTime).inSeconds;
    });

    // 4. 通知全局刷新
    qs.notifyUpdate();
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : (_endTime ?? DateTime.now());

    // 1. 选日期
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: initial.subtract(const Duration(days: 365)),
      lastDate: initial.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (date == null) return;

    // 2. 选时间
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (ctx, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (time == null) return;

    final newDt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    _updateTime(isStart, newDt);
  }

  void _confirmDelete() {
    Get.defaultDialog(
      title: "CONFIRM DELETION",
      titleStyle: AppTextStyles.panelHeader.copyWith(
        color: AppColors.accentDanger,
      ),
      content: const Text(
        "Permanently remove this time record?",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      ),
      backgroundColor: AppColors.bgPanel,
      confirmTextColor: Colors.white,
      textConfirm: "DELETE",
      textCancel: "CANCEL",
      buttonColor: AppColors.accentDanger,
      onConfirm: () {
        qs.deleteSession(widget.quest.id, widget.session.id);
        Get.back(); // Close Confirm
        Get.back(); // Close Inspector
      },
    );
  }
}
