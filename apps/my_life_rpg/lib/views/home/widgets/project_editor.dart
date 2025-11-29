// lib/views/home/widgets/project_editor.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/core/theme/theme.dart';
import 'package:my_life_rpg/core/widgets/widgets.dart';
import 'package:my_life_rpg/models/project.dart';
import 'package:my_life_rpg/services/quest_service.dart';

class ProjectEditor extends StatefulWidget {
  final Project? project; // 如果不为空，就是编辑模式

  const ProjectEditor({Key? key, this.project}) : super(key: key);

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

    return Dialog(
      backgroundColor: AppColors.bgPanel,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusLg,
        side: BorderSide(color: AppColors.accentMain.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? "CONFIGURE PROTOCOL" : "INITIATE PROTOCOL",
              style: AppTextStyles.panelHeader,
            ),
            AppSpacing.gapV24,

            // Title
            RpgInput(
              label: "PROTOCOL NAME",
              controller: titleCtrl,
              autofocus: true,
            ),
            AppSpacing.gapV12,

            // Desc
            RpgInput(label: "STRATEGIC GOAL", controller: descCtrl),
            AppSpacing.gapV12,

            // Target Hours
            Row(
              children: [
                Expanded(
                  child: Text(
                    "TARGET HOURS (0 = AUTO)",
                    style: AppTextStyles.caption,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: RpgInput(controller: hourCtrl, hint: "0"),
                ),
              ],
            ),
            AppSpacing.gapV16,

            // Color Picker
            Text("COLOR CODE", style: AppTextStyles.caption),
            AppSpacing.gapV8,
            Row(
              children: List.generate(5, (index) => _buildColorOption(index)),
            ),

            AppSpacing.gapV24,

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isEdit)
                  TextButton(
                    onPressed: () {
                      // 删除确认逻辑略
                      q.deleteProject(widget.project!.id);
                      Get.back();
                    },
                    child: Text(
                      "DELETE",
                      style: TextStyle(color: AppColors.accentDanger),
                    ),
                  ),
                const Spacer(),
                RpgButton(
                  label: "CANCEL",
                  type: RpgButtonType.ghost,
                  onTap: () => Get.back(),
                ),
                AppSpacing.gapH12,
                RpgButton(label: "ENGAGE", onTap: _submit),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(int index) {
    // 简单写一下颜色列表，和 Model 里保持一致
    final colors = [
      Colors.orangeAccent,
      Colors.cyanAccent,
      Colors.purpleAccent,
      Colors.greenAccent,
      Colors.redAccent,
    ];
    final color = colors[index];
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
}
