import 'package:flutter/material.dart';
import 'package:rpg_cyber_ui/theme/app_colors.dart';
import 'package:my_life_rpg/models/serializable.dart';

class Project implements Serializable {
  @override
  final String id;
  String title;
  String description;
  double targetHours;
  int colorIndex;

  Project({
    required this.id,
    required this.title,
    this.description = '',
    this.targetHours = 0.0,
    this.colorIndex = 0,
  });

  Color get color => AppColors.getProjectColor(colorIndex);

  // [新增] 序列化
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'targetHours': targetHours,
    'colorIndex': colorIndex,
  };

  // [新增] 反序列化
  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'],
    title: json['title'],
    description: json['description'] ?? '',
    targetHours: (json['targetHours'] as num?)?.toDouble() ?? 0.0,
    colorIndex: json['colorIndex'] ?? 0,
  );
}
