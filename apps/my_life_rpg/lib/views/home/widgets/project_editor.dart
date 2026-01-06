// lib/views/home/widgets/project_editor.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/controllers/mission_controller.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';
import 'package:my_life_rpg/models/project.dart';
import 'package:my_life_rpg/services/task_service.dart';

class ProjectEditor extends StatefulWidget {
  final Project? project; // 编辑模式
  final String? initialDirectionId; // [新增] 新建模式下的默认归属

  const ProjectEditor({super.key, this.project, this.initialDirectionId});

  @override
  State<ProjectEditor> createState() => _ProjectEditorState();
}

class _ProjectEditorState extends State<ProjectEditor> {
  final TaskService q = Get.find();
  final MissionController mc = Get.find();

  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;
  late TextEditingController hourCtrl;

  int selectedColorIdx = 0;
  String? selectedDirectionId; // 当前选中的方向ID

  @override
  void initState() {
    super.initState();

    // 1. 初始化表单控制器
    titleCtrl = TextEditingController(text: widget.project?.title ?? "");
    descCtrl = TextEditingController(text: widget.project?.description ?? "");
    hourCtrl = TextEditingController(
      text: widget.project?.targetHours.toString() ?? "0",
    );
    selectedColorIdx = widget.project?.colorIndex ?? 0;

    // 2. 确定初始方向
    if (widget.project != null) {
      // 编辑模式：使用项目原本的方向
      selectedDirectionId = widget.project!.directionId;
    } else {
      // 新建模式：优先使用传入参数，否则使用当前全局选中的方向
      selectedDirectionId =
          widget.initialDirectionId ?? mc.selectedDirectionId.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.project != null;

    return RpgDialog(
      title: isEdit ? "CONFIG PROTOCOL" : "INIT PROTOCOL",
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
        if (isEdit) AppSpacing.gapH12,

        RpgButton(label: "ENGAGE", onTap: _submit),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 所属扇区 (Direction Selector)
            _buildDirectionSelector(),

            AppSpacing.gapV16,

            // 2. 基础信息
            RpgInput(
              label: "PROTOCOL NAME",
              controller: titleCtrl,
              autofocus: !isEdit,
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

            // 3. 颜色选择
            const Text("COLOR CODE", style: AppTextStyles.caption),
            AppSpacing.gapV8,
            Row(children: List.generate(5, (i) => _buildColorOption(i))),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionSelector() {
    // 构建下拉菜单项
    final List<DropdownMenuItem<String>> items = [
      // 选项：无归属
      const DropdownMenuItem<String>(
        value: null,
        child: Text(
          "ROOT / STANDALONE",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
      // 选项：现有方向
      ...q.directions.map(
        (d) => DropdownMenuItem<String>(
          value: d.id,
          child: Row(
            children: [
              Icon(d.icon, size: 14, color: d.color),
              const SizedBox(width: 8),
              Text(
                d.title,
                style: TextStyle(
                  color: d.color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return RpgSelect<String>(
      label: "ASSIGNED SECTOR",
      value: selectedDirectionId,
      items: items,
      onChanged: (val) => setState(() => selectedDirectionId = val),
    );
  }

  Widget _buildColorOption(int index) {
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
        directionId: selectedDirectionId, // [更新]
      );
    } else {
      q.addProject(
        titleCtrl.text,
        descCtrl.text,
        hours,
        selectedColorIdx,
        directionId: selectedDirectionId, // [新增]
      );
    }
    Get.back();
  }

  void _delete() {
    if (widget.project == null) return;

    final relatedCount = q.tasks
        .where((x) => x.projectId == widget.project!.id)
        .length;

    Get.defaultDialog(
      title: "TERMINATE PROTOCOL",
      titleStyle: AppTextStyles.panelHeader.copyWith(
        color: AppColors.accentDanger,
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          "Permanently delete project '${widget.project!.title}'?\n\n"
          "$relatedCount associated missions will be DETACHED.",
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
        Get.back();
        Get.back();
      },
    );
  }
}
