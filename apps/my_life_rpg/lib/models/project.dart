class Project {
  final String id;
  final String title;
  final String description; // 比如 "S级战略目标"
  final double progress; // 0.0 - 1.0，根据旗下任务完成度计算

  Project({
    required this.id,
    required this.title,
    this.description = '',
    this.progress = 0.0,
  });
}
