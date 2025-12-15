// lib/views/session/session_summary_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';

class SessionSummaryView extends StatefulWidget {
  final int durationSeconds;
  final int logsCount;
  final bool isDaemon; // 用于判断显示文案

  const SessionSummaryView({
    super.key,
    required this.durationSeconds,
    required this.logsCount,
    required this.isDaemon,
  });

  @override
  State<SessionSummaryView> createState() => _SessionSummaryViewState();
}

class _SessionSummaryViewState extends State<SessionSummaryView>
    with SingleTickerProviderStateMixin {
  bool isMarkedComplete = false; // 用户是否勾选了“完成任务”

  @override
  Widget build(BuildContext context) {
    // 简单的时长格式化
    final minutes = widget.durationSeconds ~/ 60;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgPanel,
            border: Border.all(color: AppColors.borderDim),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              Row(
                children: [
                  const Icon(Icons.assessment, color: AppColors.accentMain),
                  AppSpacing.gapH12,
                  Text(
                    "SESSION REPORT",
                    style: AppTextStyles.panelHeader.copyWith(
                      color: AppColors.accentMain,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const RpgDivider(height: 32),

              // 2. Data Grid (Strict Data)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat("DURATION", "$minutes", "min"),
                  Container(width: 1, height: 40, color: AppColors.borderDim),
                  _buildStat("LOGS", "${widget.logsCount}", "items"),
                  // 可以加一个效率估算或者单纯显示时间
                  Container(width: 1, height: 40, color: AppColors.borderDim),
                  _buildStat("STATUS", "ACTIVE", ""),
                ],
              ),

              AppSpacing.gapV32,

              // 3. Completion Checkbox (Functional)
              _buildCompletionSwitch(),

              AppSpacing.gapV32,

              // 4. Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  RpgButton(
                    label: "DISCARD",
                    type: RpgButtonType.ghost,
                    onTap: () => Get.back(result: {'save': false}),
                  ),
                  AppSpacing.gapH12,
                  RpgButton(
                    label: "LOG ENTRY",
                    type: RpgButtonType.primary,
                    icon: Icons.save_alt,
                    onTap: () {
                      Get.back(
                        result: {'save': true, 'complete': isMarkedComplete},
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.micro.copyWith(color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: AppTextStyles.micro.copyWith(color: AppColors.accentMain),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletionSwitch() {
    final label = widget.isDaemon
        ? "MARK CYCLE COMPLETE"
        : "MARK TASK COMPLETE";
    return InkWell(
      onTap: () => setState(() => isMarkedComplete = !isMarkedComplete),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isMarkedComplete
              ? AppColors.accentSafe.withOpacity(0.1)
              : AppColors.bgInput,
          border: Border.all(
            color: isMarkedComplete
                ? AppColors.accentSafe
                : AppColors.borderDim,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              isMarkedComplete
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              color: isMarkedComplete ? AppColors.accentSafe : Colors.grey,
            ),
            AppSpacing.gapH12,
            Text(
              label,
              style: TextStyle(
                color: isMarkedComplete ? AppColors.accentSafe : Colors.white70,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
