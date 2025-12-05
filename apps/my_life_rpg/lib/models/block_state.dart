/// [BlockState]
/// 描述时间矩阵中每一个 15分钟格子的状态。
/// 这是一个纯数据模型 (View Model)，用于 UI 渲染。
class BlockState {
  /// 当前格子被哪些 Quest 占用 (实心块)
  final List<String> occupiedQuestIds;

  /// 当前格子被哪些 Session 占用 (用于连线判断)
  final List<String> occupiedSessionIds;

  /// 当前格子包含哪些 Deadline (红框)
  final List<String> deadlineQuestIds;

  // 如果非空，表示这是一个连续块的"头部"，View 层应该渲染文字
  final String? label;

  // 文字跨越的格子数 (默认为 1)
  final int span;

  BlockState({
    this.occupiedQuestIds = const [],
    this.occupiedSessionIds = const [],
    this.deadlineQuestIds = const [],
    this.label,
    this.span = 1,
  });

  /// 是否为空格 (无占用且无 Deadline)
  bool get isEmpty => occupiedQuestIds.isEmpty && deadlineQuestIds.isEmpty;

  /// 便捷工厂：创建一个空状态
  factory BlockState.empty() {
    return BlockState();
  }

  // 辅助 copyWith，方便算法层填充
  BlockState copyWith({
    List<String>? occupiedQuestIds,
    List<String>? occupiedSessionIds,
    List<String>? deadlineQuestIds,
    String? label,
    int? span,
  }) {
    return BlockState(
      occupiedQuestIds: occupiedQuestIds ?? this.occupiedQuestIds,
      occupiedSessionIds: occupiedSessionIds ?? this.occupiedSessionIds,
      deadlineQuestIds: deadlineQuestIds ?? this.deadlineQuestIds,
      label: label ?? this.label,
      span: span ?? this.span,
    );
  }
}
