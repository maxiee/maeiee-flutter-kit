import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';
import 'package:maeiee_system_toolkit/views/repo_to_prompt/file_node.dart'; // 引入模型
import 'package:maeiee_system_toolkit/views/repo_to_prompt/repo_to_prompt_controller.dart';
import 'package:maeiee_system_toolkit/views/repo_to_prompt/workspace_model.dart';

class RepoToPromptView extends GetView<RepoToPromptController> {
  const RepoToPromptView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: const Text('源码转 Prompt'),
        backgroundColor: AppColors.bgPanel,
      ),
      body: Row(
        children: [
          // 左侧侧边栏
          _buildSidebar(),
          // 右侧内容区
          const VerticalDivider(width: 1, color: AppColors.borderDim),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: AppColors.bgPanel,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: RpgButton(
                onTap: controller.createWorkspace,
                icon: Icons.add,
                label: '新建工作区',
                type: RpgButtonType.primary,
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              return ListView.builder(
                itemCount: controller.workspaces.length,
                itemBuilder: (context, index) {
                  final ws = controller.workspaces[index];
                  return _buildWorkspaceItem(ws);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceItem(WorkspaceModel ws) {
    return Obx(() {
      final isSelected = controller.currentWorkspaceId.value == ws.id;
      return Container(
        color: isSelected
            ? AppColors.accentMain.withOpacity(0.1)
            : Colors.transparent,
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
          title: Text(
            ws.title,
            style: TextStyle(
              color: isSelected ? AppColors.accentMain : AppColors.textDim,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            // 简单的日期格式化，或者只显示文件数
            '${ws.rootPaths.length} 个项目',
            style: const TextStyle(fontSize: 10, color: AppColors.textDim),
          ),
          onTap: () => controller.selectWorkspace(ws.id),
          trailing: isSelected
              ? PopupMenuButton(
                  icon: const Icon(
                    Icons.more_horiz,
                    size: 16,
                    color: AppColors.textDim,
                  ),
                  padding: EdgeInsets.zero,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('重命名'),
                      onTap: () {
                        // 延时执行弹窗，避免 PopupMenu 关闭冲突
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _showRenameDialog(ws);
                        });
                      },
                    ),
                    PopupMenuItem(
                      child: const Text(
                        '删除',
                        style: TextStyle(color: AppColors.accentDanger),
                      ),
                      onTap: () => controller.deleteWorkspace(ws.id),
                    ),
                  ],
                )
              : null,
        ),
      );
    });
  }

  void _showRenameDialog(WorkspaceModel ws) {
    final textCtrl = TextEditingController(text: ws.title);
    Get.dialog(
      RpgDialog(
        title: '重命名工作区',
        child: RpgInput(controller: textCtrl, autofocus: true),
        actions: [
          RpgButton(
            onTap: () {
              controller.updateWorkspaceTitle(ws.id, textCtrl.text.trim());
              Get.back();
            },
            label: '确定',
          ),
        ],
      ),
    );
  }

  // 原 body 内容移动到这里
  Widget _buildMainContent() {
    return DropTarget(
      onDragDone: (detail) {
        final paths = detail.files.map((e) => e.path).toList();
        controller.handleDropFiles(paths);
        controller.isDraggingHover.value = false;
      },
      onDragEntered: (detail) => controller.isDraggingHover.value = true,
      onDragExited: (detail) => controller.isDraggingHover.value = false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildControlPanel(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildFileTreeArea(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildFileTreeArea() {
    return RpgContainer(
      style: RpgContainerStyle.panel,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(
                  Icons.account_tree_outlined,
                  size: 16,
                  color: AppColors.textDim,
                ),
                const SizedBox(width: 8),
                Text(
                  '文件结构筛选',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
          const RpgDivider(),
          Expanded(
            child: Obx(() {
              if (controller.fileTreeRoots.isEmpty) {
                return Center(
                  child: Text(
                    '请先导入项目',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textDim,
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: controller.fileTreeRoots.length,
                itemBuilder: (context, index) {
                  return _buildFileNode(controller.fileTreeRoots[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // 递归构建树节点组件
  Widget _buildFileNode(FileNode node) {
    Widget leadingIcon;
    if (node.isDirectory) {
      leadingIcon = const Icon(
        Icons.folder,
        size: 16,
        color: AppColors.accentMain,
      );
    } else {
      leadingIcon = const Icon(
        Icons.insert_drive_file,
        size: 16,
        color: AppColors.textSecondary,
      );
    }

    if (node.isDirectory) {
      return Obx(
        () => ExpansionTile(
          key: PageStorageKey(node.path),
          initiallyExpanded: node.isExpanded.value,
          onExpansionChanged: (val) => node.isExpanded.value = val,
          tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          visualDensity: VisualDensity.compact,
          leading: SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: node.isSelected.value,
              onChanged: (val) => controller.toggleNode(node, val),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppColors.accentMain,
            ),
          ),
          title: Row(
            children: [
              leadingIcon,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.name,
                  style: AppTextStyles.body,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.only(left: 20),
          children: node.children
              .map((child) => _buildFileNode(child))
              .toList(),
        ),
      );
    } else {
      return Obx(
        () => ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 0,
          ),
          visualDensity: VisualDensity.compact,
          leading: SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: node.isSelected.value,
              onChanged: (val) => controller.toggleNode(node, val),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppColors.accentMain,
            ),
          ),
          title: Row(
            children: [
              leadingIcon,
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.name,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 显示单个文件的大小
              Text(
                _formatFileSize(node.size),
                style: AppTextStyles.caption.copyWith(color: AppColors.textDim),
              ),
            ],
          ),
          onTap: () => controller.toggleNode(node, !node.isSelected.value),
        ),
      );
    }
  }

  Widget _buildControlPanel() {
    return Obx(() {
      final isHovering = controller.isDraggingHover.value;

      return RpgContainer(
        style: RpgContainerStyle.card,
        focused: isHovering,
        child: Row(
          children: [
            RpgButton(
              onTap: controller.isLoading.value
                  ? null
                  : controller.pickDirectory,
              icon: Icons.add_circle_outline,
              label: '导入项目',
              type: RpgButtonType.secondary,
              compact: true,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                controller.selectedPath.value.isEmpty
                    ? '拖拽文件夹到此处或点击导入'
                    : controller.selectedPath.value,
                style: AppTextStyles.body.copyWith(color: AppColors.textDim),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 估算显示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    size: 16,
                    color: AppColors.textDim,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() {
                        if (controller.statusMessage.isNotEmpty &&
                            controller.statusMessage.value != '就绪') {
                          return Text(
                            controller.statusMessage.value,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accentDanger,
                            ),
                          );
                        }
                        return Text(
                          '预估消耗 (基于文件大小)',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textDim,
                          ),
                        );
                      }),
                      Obx(
                        () => Text(
                          '~${_formatTokenCount(controller.estimatedTokens.value)} Tokens',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // 生成按钮
            Expanded(
              child: SizedBox(
                height: 48,
                child: Obx(
                  () => RpgButton(
                    onTap: controller.fileTreeRoots.isEmpty
                        ? null
                        : controller.generateAndPreview,
                    label: '生成并预览',
                    type: RpgButtonType.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatTokenCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    }
    return count.toString();
  }
}
