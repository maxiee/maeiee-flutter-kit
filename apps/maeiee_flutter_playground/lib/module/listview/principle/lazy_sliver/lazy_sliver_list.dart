import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:maeiee_flutter_playground/module/listview/principle/lazy_sliver/render_lazy_sliver_list.dart';

/// 1. Widget 定义
/// 这是一个配置类，它不直接持有 children 列表，而是持有一个 builder。
class LazySliverList extends RenderObjectWidget {
  final IndexedWidgetBuilder builder;
  final int itemCount;
  final double itemExtent; // 为简化布局计算，本篇假设所有 Item 高度固定

  const LazySliverList({
    super.key,
    required this.builder,
    required this.itemCount,
    required this.itemExtent,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    // context 本身就是 Element，它实现了 RenderSliverBoxChildManager
    return RenderLazySliverList(
      childManager: context as RenderSliverBoxChildManager,
      itemExtent: itemExtent,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLazySliverList renderObject,
  ) {
    renderObject.itemExtent = itemExtent;
  }

  @override
  RenderObjectElement createElement() => LazySliverListElement(this);
}

/// 2. Element 定义 (充当 Manager 角色)
/// 它负责管理子 Element 的生命周期（创建、更新、销毁）。
class LazySliverListElement extends RenderObjectElement
    implements RenderSliverBoxChildManager {
  LazySliverListElement(LazySliverList super.widget);

  // 缓存当前活跃的子 Element，Key 为 index。
  // 当 RenderObject 请求创建子节点时，我们将结果存入此 Map。
  final Map<int, Element> _childElements = {};

  // 临时变量，用于辅助 insertRenderObjectChild 确定插入位置
  RenderBox? _currentAfterChild;

  @override
  LazySliverList get widget => super.widget as LazySliverList;

  @override
  RenderLazySliverList get renderObject =>
      super.renderObject as RenderLazySliverList;

  @override
  int get childCount => widget.itemCount;

  @override
  int? get estimatedChildCount => widget.itemCount;

  /// [核心方法] RenderObject 在布局时会调用此方法请求创建子节点
  /// index: 请求的索引
  /// after: 新节点应该插入到哪个 RenderBox 之后（用于维护链表顺序）
  @override
  void createChild(int index, {required RenderBox? after}) {
    if (index < 0 || index >= childCount) return;

    owner!.buildScope(this, () {
      _currentAfterChild = after;

      // 1. 调用 Widget 的 builder 构建 Widget
      Widget? childWidget = widget.builder(this, index);

      // 2. 将 Widget 挂载到 Element 树上 (inflate)
      // updateChild 是 Framework 核心方法：
      // 如果 _childElements[index] 为空，则创建新 Element；否则更新现有 Element。
      Element? newElement = updateChild(
        _childElements[index],
        childWidget,
        index,
      );

      if (newElement != null) {
        _childElements[index] = newElement;
      }
      _currentAfterChild = null;
    });
  }

  /// [核心方法] RenderObject 在布局时认为某个节点不可见，请求销毁
  @override
  void removeChild(RenderBox child) {
    final index = renderObject.indexOf(child);

    if (_childElements.containsKey(index)) {
      owner!.buildScope(this, () {
        // 传入 null widget 会导致对应的 Element 被 unmount (从树中移除并销毁)
        updateChild(_childElements[index], null, index);
        _childElements.remove(index);
      });
    }
  }

  /// 当 Element mount 时，Framework 会回调此方法将 RenderObject 插入树中
  @override
  void insertRenderObjectChild(RenderObject child, Object? slot) {
    // 将生成的 RenderBox 插入到 RenderSliver 的子节点双向链表中
    renderObject.insert(child as RenderBox, after: _currentAfterChild);
  }

  @override
  void moveRenderObjectChild(
    RenderObject child,
    Object? oldSlot,
    Object? newSlot,
  ) {
    // 本例不涉及移动操作
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) {
    renderObject.remove(child as RenderBox);
  }

  @override
  void forgetChild(Element child) {
    // 当子 Element 被销毁时，清理 Map 缓存
    _childElements.remove(child.slot);
    super.forgetChild(child);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    _childElements.values.forEach(visitor);
  }

  // 简化实现：不做复杂的滚动预估
  @override
  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int? firstIndex,
    int? lastIndex,
    double? leadingScrollOffset,
    double? trailingScrollOffset,
  }) {
    return double.infinity;
  }

  @override
  void didAdoptChild(RenderBox child) {}
  @override
  void setDidUnderflow(bool value) {}
  @override
  void didStartLayout() {}
  @override
  void didFinishLayout() {}
  @override
  bool debugAssertChildListLocked() => true;
}
