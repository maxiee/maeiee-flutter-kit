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

  BlockState({
    this.occupiedQuestIds = const [],
    this.occupiedSessionIds = const [],
    this.deadlineQuestIds = const [],
  });

  /// 是否为空格 (无占用且无 Deadline)
  bool get isEmpty => occupiedQuestIds.isEmpty && deadlineQuestIds.isEmpty;

  /// 便捷工厂：创建一个空状态
  factory BlockState.empty() {
    return BlockState();
  }
}
