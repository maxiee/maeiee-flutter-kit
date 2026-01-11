import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_life_rpg/views/calendar/calendar_pages.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';
import 'package:my_life_rpg/services/time_service.dart';

class DateControllerBar extends StatelessWidget {
  final TimeService t = Get.find();

  DateControllerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        // [调整] 背景色稍微加深一点，增加对比度
        color: const Color(0xFF1A1A1A),
        border: const Border(
          top: BorderSide(color: AppColors.borderDim),
          left: BorderSide(color: AppColors.borderDim),
          right: BorderSide(color: AppColors.borderDim),
          bottom: BorderSide(color: Colors.white10), // 加个底边分割
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Obx(() {
        final date = t.selectedDate.value;
        final now = DateTime.now();
        final isToday =
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final weekDay = DateFormat('EEE').format(date).toUpperCase();

        return Row(
          children: [
            // 1. Prev Day
            _iconBtn(
              Icons.chevron_left,
              () => t.changeDate(date.subtract(const Duration(days: 1))),
            ),

            // 2. Date Display
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(context, date),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        weekDay,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          color: AppColors.accentMain,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Next Day
            _iconBtn(
              Icons.chevron_right,
              () => t.changeDate(date.add(const Duration(days: 1))),
            ),

            // 分割线
            Container(
              width: 1,
              height: 20,
              color: Colors.white12,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),

            // 4. Reset to Today
            if (!isToday)
              _iconBtn(
                Icons.today,
                () => t.changeDate(DateTime.now()),
                color: AppColors.accentSafe,
                tooltip: "JUMP TO NOW",
              ),

            // [新增] 5. View Switchers (Week / Month)
            _iconBtn(
              Icons.view_week,
              () => Get.to(() => const WeekViewPage()),
              tooltip: "WEEK PROTOCOL",
            ),
            _iconBtn(
              Icons.calendar_view_month,
              () => Get.to(() => const MonthViewPage()),
              tooltip: "STRATEGIC OVERVIEW",
            ),
          ],
        );
      }),
    );
  }

  Widget _iconBtn(
    IconData icon,
    VoidCallback onTap, {
    Color? color,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? "",
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: color ?? Colors.grey, size: 20),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (picked != null) {
      t.changeDate(picked);
    }
  }
}
