import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:maeiee_flutter_playground/module/listview/principle/lazy_sliver_v2/render_lazy_sliver_list_v2.dart';

class LazySliverListV2 extends RenderObjectWidget {
  final IndexedWidgetBuilder builder;
  final int itemCount;
  final double itemExtent;
  final double cacheExtent; // 新增

  const LazySliverListV2({
    super.key,
    required this.builder,
    required this.itemCount,
    required this.itemExtent,
    this.cacheExtent = 0.0,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderLazySliverListV2(
      childManager: context as RenderSliverBoxChildManager,
      itemExtent: itemExtent,
      cacheExtent: cacheExtent,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLazySliverListV2 renderObject,
  ) {
    renderObject
      ..itemExtent = itemExtent
      ..cacheExtent = cacheExtent;
  }

  @override
  RenderObjectElement createElement() => LazySliverListElement(this);
}

/// 4. Element (Manager)
class LazySliverListElement extends RenderObjectElement
    implements RenderSliverBoxChildManager {
  LazySliverListElement(LazySliverListV2 super.widget);

  final Map<int, Element> _childElements = {};
  RenderBox? _currentAfterChild;

  @override
  LazySliverListV2 get widget => super.widget as LazySliverListV2;

  @override
  RenderLazySliverListV2 get renderObject =>
      super.renderObject as RenderLazySliverListV2;

  @override
  int get childCount => widget.itemCount;

  @override
  int? get estimatedChildCount => widget.itemCount;

  @override
  void createChild(int index, {required RenderBox? after}) {
    if (index < 0 || index >= childCount) return;
    owner!.buildScope(this, () {
      _currentAfterChild = after;
      Widget? childWidget = widget.builder(this, index);
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

  @override
  void removeChild(RenderBox child) {
    final index = renderObject.indexOf(child);
    if (_childElements.containsKey(index)) {
      owner!.buildScope(this, () {
        updateChild(_childElements[index], null, index);
        _childElements.remove(index);
      });
    }
  }

  @override
  void insertRenderObjectChild(RenderObject child, Object? slot) {
    renderObject.insert(child as RenderBox, after: _currentAfterChild);
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) {
    renderObject.remove(child as RenderBox);
  }

  @override
  void moveRenderObjectChild(
    RenderObject child,
    Object? oldSlot,
    Object? newSlot,
  ) {}

  @override
  void forgetChild(Element child) {
    _childElements.remove(child.slot);
    super.forgetChild(child);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    _childElements.values.forEach(visitor);
  }

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
