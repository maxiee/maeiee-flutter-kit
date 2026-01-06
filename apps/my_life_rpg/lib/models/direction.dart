import 'package:flutter/material.dart';
import 'package:rpg_cyber_ui/theme/app_colors.dart';
import 'package:my_life_rpg/models/serializable.dart';

class Direction implements Serializable {
  @override
  final String id;
  String title; // e.g. "CAREER", "BIO-HACKING"
  String description;
  int colorIndex; // 沿用系统的颜色索引
  int iconPoint; // 存储 IconData 的 codePoint

  Direction({
    required this.id,
    required this.title,
    this.description = '',
    this.colorIndex = 0,
    this.iconPoint = 0xe145, // 默认图标 (Icons.category)
  });

  Color get color => AppColors.getProjectColor(colorIndex);
  IconData get icon => IconData(iconPoint, fontFamily: 'MaterialIcons');

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'colorIndex': colorIndex,
    'iconPoint': iconPoint,
  };

  factory Direction.fromJson(Map<String, dynamic> json) => Direction(
    id: json['id'],
    title: json['title'],
    description: json['description'] ?? '',
    colorIndex: json['colorIndex'] ?? 0,
    iconPoint: json['iconPoint'] ?? 0xe145,
  );
}
