class WorkspaceModel {
  String id;
  String title;
  List<String> rootPaths;
  // 存储被取消勾选的文件路径，用于恢复状态
  List<String> unselectedPaths;
  DateTime updatedAt;

  WorkspaceModel({
    required this.id,
    required this.title,
    required this.rootPaths,
    required this.unselectedPaths,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'rootPaths': rootPaths,
      'unselectedPaths': unselectedPaths,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WorkspaceModel.fromJson(Map<dynamic, dynamic> json) {
    return WorkspaceModel(
      id: json['id'] as String,
      title: json['title'] as String,
      rootPaths: (json['rootPaths'] as List).cast<String>(),
      unselectedPaths: (json['unselectedPaths'] as List).cast<String>(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
