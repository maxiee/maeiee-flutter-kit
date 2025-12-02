// lib/views/home/widgets/project_editor.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import 'package:my_life_rpg/models/project.dart';
import 'package:my_life_rpg/services/quest_service.dart';

class ProjectEditor extends StatefulWidget {
  final Project? project; // 如果不为空，就是编辑模式

  const ProjectEditor({super.key, this.project});

  @override
  State<ProjectEditor> createState() => _ProjectEditorState();
}

class _ProjectEditorState extends State<ProjectEditor> {
  final QuestService q = Get.find();

  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;
  late TextEditingController hourCtrl;

  int selectedColorIdx = 0;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.project?.title ?? "");
    descCtrl = TextEditingController(text: widget.project?.description ?? "");
    hourCtrl = TextEditingController(
      text: widget.project?.targetHours.toString() ?? "0",
    );
    selectedColorIdx = widget.project?.colorIndex ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.project != null;

    return RpgDialog(
      title: isEdit ? "CONFIGURE PROTOCOL" : "INITIATE PROTOCOL",
      icon: isEdit ? Icons.settings : Icons.add_circle_outline,
      accentColor: AppColors.accentMain,
      actions: [
        if (isEdit)
          TextButton(
            onPressed: _delete,
            child: const Text(
              "DELETE",
              style: TextStyle(color: AppColors.accentDanger),
            ),
          ),
        // 如果是编辑模式且有删除按钮，加个间距
        if (isEdit) AppSpacing.gapH12,

        RpgButton(label: "ENGAGE", onTap: _submit),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RpgInput(
              label: "PROTOCOL NAME",
              controller: titleCtrl,
              autofocus: true,
            ),
            AppSpacing.gapV12,
            RpgInput(label: "STRATEGIC GOAL", controller: descCtrl),
            AppSpacing.gapV12,
            Row(
              children: [
                const Expanded(
                  child: Text("TARGET HOURS", style: AppTextStyles.caption),
                ),
                SizedBox(
                  width: 100,
                  child: RpgInput(controller: hourCtrl, hint: "0"),
                ),
              ],
            ),
            AppSpacing.gapV16,
            const Text("COLOR CODE", style: AppTextStyles.caption),
            AppSpacing.gapV8,
            Row(children: List.generate(5, (i) => _buildColorOption(i))),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(int index) {
    // 简单写一下颜色列表，和 Model 里保持一致
    final color = AppColors.getProjectColor(index);
    final isSelected = selectedColorIdx == index;

    return GestureDetector(
      onTap: () => setState(() => selectedColorIdx = index),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          border: Border.all(
            color: isSelected ? Colors.white : color,
            width: isSelected ? 2 : 1,
          ),
          shape: BoxShape.circle,
        ),
        child: isSelected
            ? Center(child: Container(width: 8, height: 8, color: Colors.white))
            : null,
      ),
    );
  }

  void _submit() {
    if (titleCtrl.text.isEmpty) return;
    final hours = double.tryParse(hourCtrl.text) ?? 0.0;

    if (widget.project != null) {
      q.updateProject(
        widget.project!.id,
        title: titleCtrl.text,
        desc: descCtrl.text,
        targetHours: hours,
        colorIdx: selectedColorIdx,
      );
    } else {
      q.addProject(titleCtrl.text, descCtrl.text, hours, selectedColorIdx);
    }
    Get.back();
  }

  void _delete() {
    if (widget.project == null) return;

    // 获取关联任务数量，用于提示文案
    final relatedCount = q.quests
        .where((x) => x.projectId == widget.project!.id)
        .length;

    // 使用我们封装好的 RpgDialog ? 不，这里是确认弹窗，Get.defaultDialog 或 RpgDialog 都可以。
    // 为了快速，使用 Get.defaultDialog
    Get.defaultDialog(
      title: "TERMINATE PROTOCOL",
      titleStyle: AppTextStyles.panelHeader.copyWith(
        color: AppColors.accentDanger,
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          "Permanently delete project '${widget.project!.title}'?\n\n"
          "$relatedCount associated missions will be DETACHED (converted to Standalone), not deleted.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
      backgroundColor: AppColors.bgPanel,
      confirmTextColor: Colors.white,
      textConfirm: "CONFIRM",
      textCancel: "CANCEL",
      buttonColor: AppColors.accentDanger,
      onConfirm: () {
        q.deleteProject(widget.project!.id);
        Get.back(); // Close Confirm
        Get.back(); // Close Editor
        // 使用 Toast 提示 (如果我们启用了 ToastUtils)
        // ToastUtils.showSuccess("Project deleted. Missions detached.");
      },
    );
  }
}
