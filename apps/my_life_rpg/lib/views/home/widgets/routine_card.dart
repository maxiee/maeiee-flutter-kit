import 'package:flutter/material.dart';
import '../../../models/quest.dart';

/// 像系统的“健康监控日志”。
class RoutineCard extends StatelessWidget {
  final Quest quest;
  const RoutineCard({Key? key, required this.quest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dueDays = quest.dueDays ?? 0;
    final isOverdue = dueDays > 0;
    final color = isOverdue ? Colors.redAccent : Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: color, width: 4)), // 左边框指示状态
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              quest.title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isOverdue ? "OVERDUE +$dueDays d" : "READY in ${-dueDays} d",
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
