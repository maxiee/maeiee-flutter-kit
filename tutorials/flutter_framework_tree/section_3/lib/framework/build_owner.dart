import 'dart:ui';
import 'package:section_1/framework/element.dart';

class MyBuildOwner {
  // 增加回调：当有构建任务被调度时触发
  final VoidCallback onBuildScheduled;

  MyBuildOwner({required this.onBuildScheduled});

  // 脏元素列表：存储所有需要重建的 Element
  final List<MyElement> _dirtyElements = [];

  // 标记一个 Element 为脏，计划在下一帧重建
  void scheduleBuildFor(MyElement element) {
    if (!_dirtyElements.contains(element)) {
      _dirtyElements.add(element);
      // 一旦有脏节点加入，立即请求调度下一帧
      onBuildScheduled();
    }
  }

  // 清理脏元素列表，执行重建
  // 这个方法应该在每一帧开始时调用
  void flushBuild() {
    // 也就是 Flutter 里的 buildScope
    // 为了防止在遍历过程中列表被修改，我们需要先复制一份或按序处理
    // 这里做极简处理
    for (var element in List.of(_dirtyElements)) {
      if (element.dirty) {
        element.rebuild();
      }
    }
    _dirtyElements.clear();
  }
}
