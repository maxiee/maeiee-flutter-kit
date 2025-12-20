import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
        color: AppColors.bgInput.withOpacity(0.5),
        border: const Border(
          top: BorderSide(color: AppColors.borderDim),
          left: BorderSide(color: AppColors.borderDim),
          right: BorderSide(color: AppColors.borderDim),
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

        // 格式化： "2023-10-24 [TUE]"
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final weekDay = DateFormat('EEE').format(date).toUpperCase();

        return Row(
          children: [
            // 1. Prev Day
            _iconBtn(
              Icons.chevron_left,
              () => t.changeDate(date.subtract(const Duration(days: 1))),
            ),

            // 2. Date Display (Click to Pick)
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

            // 4. Reset to Today (Only if not today)
            if (!isToday) ...[
              Container(
                width: 1,
                height: 20,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
              InkWell(
                onTap: () => t.changeDate(DateTime.now()),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: const Icon(
                    Icons.today,
                    size: 18,
                    color: AppColors.accentSafe,
                  ),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, color: Colors.grey, size: 20),
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
