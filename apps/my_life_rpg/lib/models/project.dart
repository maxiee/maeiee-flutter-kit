// lib/models/project.dart
import 'package:flutter/material.dart'; // 为了存 Color，或者存 int colorValue

class Project {
  final String id;
  String title;
  String description;
  // 目标投入小时数 (用于计算进度: currentHours / targetHours)
  // 如果为 0，则按任务完成数计算
  double targetHours;
  // 主题色索引 (0=Orange, 1=Blue, 2=Green...)
  // 存 int 方便序列化，或者直接存 String hex
  int colorIndex;

  // 运行时动态属性 (不需要序列化)
  // double progress; // 这个交给 Service 动态算，不要存

  Project({
    required this.id,
    required this.title,
    this.description = '',
    this.targetHours = 0.0,
    this.colorIndex = 0,
  });

  // 简单的颜色映射辅助
  Color get color {
    const colors = [
      Colors.orangeAccent, // 0: Default
      Colors.cyanAccent, // 1: Tech
      Colors.purpleAccent, // 2: Art
      Colors.greenAccent, // 3: Health
      Colors.redAccent, // 4: Critical
    ];
    if (colorIndex < 0 || colorIndex >= colors.length) return colors[0];
    return colors[colorIndex];
  }
}
