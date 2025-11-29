import 'package:flutter/material.dart';

class Project {
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

  Color get color {
    const colors = [
      Colors.orangeAccent,
      Colors.cyanAccent,
      Colors.purpleAccent,
      Colors.greenAccent,
      Colors.redAccent,
    ];
    if (colorIndex < 0 || colorIndex >= colors.length) return colors[0];
    return colors[colorIndex];
  }

  // [新增] 序列化
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
