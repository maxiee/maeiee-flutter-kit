import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';
import 'package:my_life_rpg/services/task_service.dart';
import 'package:my_life_rpg/core/domain/time_domain.dart';

class TacticalAnalysisDialog extends StatefulWidget {
  const TacticalAnalysisDialog({super.key});

  @override
  State<TacticalAnalysisDialog> createState() => _TacticalAnalysisDialogState();
}

class _TacticalAnalysisDialogState extends State<TacticalAnalysisDialog> {
  final TaskService qs = Get.find();

  // 交互状态：用户手指按在柱状图上的位置
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    // --- 1. 数据准备 (Data Prep) ---
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 过去7天
    final weekDates = List.generate(
      7,
      (i) => today.subtract(Duration(days: 6 - i)),
    );
    final allSessions = qs.tasks.expand((t) => t.sessions).toList();

    // 柱状图数据：每天的小时数
    final dailyHours = weekDates.map((date) {
      final seconds = TimeDomain.calculateEffectiveSeconds(allSessions, date);
      return seconds / 3600.0;
    }).toList();

    // 计算 Y 轴最大值 (为了图表美观，向上取整)
    double maxHour = dailyHours.reduce((a, b) => a > b ? a : b);
    if (maxHour < 4) maxHour = 4;
    maxHour = (maxHour + 1).ceilToDouble();

    // 饼图数据：项目分布
    final startOfPeriod = today.subtract(const Duration(days: 6));
    final projectStats = <String, double>{};
    double totalSeconds = 0;

    for (var task in qs.tasks) {
      for (var s in task.sessions) {
        if (s.startTime.isAfter(startOfPeriod)) {
          final dur = s.effectiveSeconds.toDouble();
          final pid = task.projectId ?? "standalone";
          projectStats[pid] = (projectStats[pid] ?? 0) + dur;
          totalSeconds += dur;
        }
      }
    }

    // 排序并取 Top 5，其余归为 "Other"
    final sortedEntries = projectStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // --- 2. UI 构建 ---
    return RpgDialog(
      title: "TACTICAL ANALYSIS (7D)",
      icon: Icons.pie_chart_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. 柱状图区域
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const RpgText.caption("MOMENTUM LOG"),
              RpgText.micro("PEAK: ${maxHour.toInt()}h", color: Colors.grey),
            ],
          ),
          AppSpacing.gapV24,
          SizedBox(
            height: 160,
            child: _buildBarChart(dailyHours, weekDates, maxHour),
          ),

          AppSpacing.gapV24,
          const RpgDivider(),
          AppSpacing.gapV16,

          // B. 饼图区域
          const RpgText.caption("RESOURCE ALLOCATION"),
          AppSpacing.gapV24,

          if (totalSeconds == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "NO DATA SIGNATURE DETECTED",
                  style: TextStyle(color: Colors.grey, fontFamily: 'Courier'),
                ),
              ),
            )
          else
            Row(
              children: [
                // 饼图本体
                SizedBox(
                  height: 140,
                  width: 140,
                  child: _buildPieChart(sortedEntries, totalSeconds),
                ),
                AppSpacing.gapH24,
                // 图例 (Legend)
                Expanded(child: _buildLegend(sortedEntries, totalSeconds)),
              ],
            ),
        ],
      ),
    );
  }

  // --- Chart 1: Bar Chart (柱状图) ---
  Widget _buildBarChart(
    List<double> dailyHours,
    List<DateTime> dates,
    double maxY,
  ) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        // 触摸交互配置
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            // tooltipBgColor: AppColors.bgPanel, // 旧版 API
            getTooltipColor: (_) => AppColors.bgPanel, // 新版 API
            tooltipBorder: const BorderSide(color: AppColors.accentMain),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                "${rod.toY.toStringAsFixed(1)}h",
                const TextStyle(
                  color: AppColors.accentMain,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              );
            },
          ),
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  barTouchResponse == null ||
                  barTouchResponse.spot == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
            });
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          // 隐藏上、右
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          // 左侧刻度
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: maxY > 8 ? 2 : 1, // 动态间隔
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontFamily: 'Courier',
                  ),
                );
              },
            ),
          ),
          // 底部日期
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dates.length)
                  return const SizedBox.shrink();
                final date = dates[index];
                final isToday = index == 6; // 最后一个是今天
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat(
                      'E',
                    ).format(date).toUpperCase()[0], // 只显示首字母 M/T/W...
                    style: TextStyle(
                      color: isToday ? AppColors.accentMain : Colors.grey,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        // 核心数据
        barGroups: dailyHours.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;
          final isTouched = index == touchedIndex;
          final isToday = index == 6;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: isToday
                    ? AppColors.accentSafe
                    : (isTouched ? Colors.white : AppColors.accentMain),
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY, // 背景填满
                  color: Colors.white.withOpacity(0.02),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // --- Chart 2: Pie Chart (甜甜圈图) ---
  Widget _buildPieChart(List<MapEntry<String, double>> entries, double total) {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30, // 甜甜圈内径
        sections: entries.map((entry) {
          final pid = entry.key;
          final value = entry.value;
          final percent = value / total;

          Color color;
          if (pid == 'standalone') {
            color = Colors.grey;
          } else {
            final p = qs.projects.firstWhereOrNull((x) => x.id == pid);
            color = p?.color ?? Colors.white24;
          }

          // 选中状态稍微变大 (这里简化处理，不做交互变大了，保持KISS)
          return PieChartSectionData(
            color: color,
            value: value,
            title: "${(percent * 100).toInt()}%",
            radius: 40,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Courier',
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Legend (图例列表) ---
  Widget _buildLegend(List<MapEntry<String, double>> entries, double total) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: entries.map((entry) {
        final pid = entry.key;
        final value = entry.value;
        final percent = value / total;

        String label;
        Color color;
        if (pid == 'standalone') {
          label = "MISC / STANDALONE";
          color = Colors.grey;
        } else {
          final p = qs.projects.firstWhereOrNull((x) => x.id == pid);
          label = p?.title ?? "UNKNOWN";
          color = p?.color ?? Colors.white24;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(width: 8, height: 8, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "${(value / 3600).toStringAsFixed(1)}h",
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
