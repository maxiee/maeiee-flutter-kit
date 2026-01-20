import 'package:flutter/rendering.dart';
import 'package:maeiee_flutter_playground/module/listview/principle/lazy_sliver_v2/lazy_list_keep_alive.dart';

class RenderLazySliverListV2 extends RenderSliver
    with
        ContainerRenderObjectMixin<RenderBox, SliverMultiBoxAdaptorParentData>,
        RenderSliverHelpers {
  final RenderSliverBoxChildManager childManager;
  double itemExtent;
  double cacheExtent; // [新增] 缓存区大小

  // [新增] 存放 KeepAlive 的口袋
  final Map<int, RenderBox> _keepAliveBucket = {};

  RenderLazySliverListV2({
    required this.childManager,
    required this.itemExtent,
    required this.cacheExtent, // [修改] 构造函数参数
  });

  @override
  void setupParentData(RenderObject child) {
    // [修改] 使用 SliverKeepAliveParentData
    if (child.parentData is! SliverKeepAliveParentData) {
      child.parentData = SliverKeepAliveParentData();
    }
  }

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final double scrollOffset =
        constraints.scrollOffset + constraints.cacheOrigin;
    final double visibleHeight =
        constraints.remainingPaintExtent + constraints.remainingCacheExtent;

    // [修改] 1. 计算包含 CacheExtent 的范围
    final double targetStart = (scrollOffset - cacheExtent).clamp(
      0.0,
      double.infinity,
    );
    final double targetEnd = scrollOffset + visibleHeight + cacheExtent;

    final int firstIndex = (targetStart / itemExtent).floor();
    final int lastIndex = (targetEnd / itemExtent).ceil();

    final int targetFirstIndex = firstIndex.clamp(
      0,
      childManager.childCount - 1,
    );
    final int targetLastIndex = lastIndex.clamp(0, childManager.childCount - 1);

    // 2. [垃圾回收 GC]
    final List<RenderBox> childrenToRemove = [];
    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData as SliverMultiBoxAdaptorParentData;
      final index = parentData.index!;
      if (index < targetFirstIndex || index > targetLastIndex) {
        childrenToRemove.add(child);
      }
      child = childAfter(child);
    }

    // [修改] 处理移除逻辑：区分 KeepAlive 和 真正销毁
    for (var child in childrenToRemove) {
      final parentData = child.parentData as SliverKeepAliveParentData;
      if (parentData.keepAlive) {
        // [新增] 如果标记为 KeepAlive，从链表移除，存入口袋
        invokeLayoutCallback((c) {
          remove(child);
        });
        _keepAliveBucket[parentData.index!] = child;
      } else {
        // 否则通知 Manager 销毁
        invokeLayoutCallback((SliverConstraints c) {
          childManager.removeChild(child);
        });
      }
    }

    // 3. [按需创建 & 布局]
    RenderBox? currentChild = firstChild;

    for (int index = targetFirstIndex; index <= targetLastIndex; index++) {
      RenderBox? child;

      if (currentChild != null) {
        final parentData =
            currentChild.parentData as SliverMultiBoxAdaptorParentData;
        if (parentData.index == index) {
          child = currentChild;
          currentChild = childAfter(currentChild);
        }
      }

      // [修改] 创建逻辑：先查口袋
      if (child == null) {
        if (_keepAliveBucket.containsKey(index)) {
          // [新增] 命中缓存，复活！
          child = _keepAliveBucket.remove(index);
          // 这里的 insert 只是挂载 RenderObject，不需要 invokeLayoutCallback 调用 createChild
          invokeLayoutCallback((c) {
            insert(child!, after: _findChildByIndex(index - 1));
          });
        } else {
          // [原有逻辑] 口袋没有，新建
          invokeLayoutCallback((SliverConstraints c) {
            RenderBox? anchor = _findChildByIndex(index - 1);
            childManager.createChild(index, after: anchor);
          });

          RenderBox? anchor = _findChildByIndex(index - 1);
          if (anchor != null) {
            child = childAfter(anchor);
          } else {
            child = firstChild;
          }
        }
      }

      // 3. 布局
      if (child != null) {
        final parentData = child.parentData as SliverMultiBoxAdaptorParentData;
        parentData.index = index;
        parentData.layoutOffset = index * itemExtent;

        child.layout(
          constraints.asBoxConstraints(
            minExtent: itemExtent,
            maxExtent: itemExtent,
          ),
        );
      }
    }

    // 4. [提交几何信息]
    final double totalHeight = childManager.childCount * itemExtent;

    geometry = SliverGeometry(
      scrollExtent: totalHeight,
      paintExtent: calculatePaintOffset(
        constraints,
        from: 0.0,
        to: totalHeight,
      ),
      maxPaintExtent: totalHeight,
    );

    childManager.didFinishLayout();
  }

  // 辅助方法保持不变
  RenderBox? _findChildByIndex(int index) {
    RenderBox? child = firstChild;
    while (child != null) {
      final data = child.parentData as SliverMultiBoxAdaptorParentData;
      if (data.index == index) return child;
      child = childAfter(child);
    }
    return null;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // 保持您的实现不变
    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData as SliverMultiBoxAdaptorParentData;
      if (parentData.index != null && parentData.layoutOffset != null) {
        final double childLayoutOffset = parentData.layoutOffset!;
        final double mainAxisPaintOffset =
            childLayoutOffset - constraints.scrollOffset;
        context.paintChild(child, offset + Offset(0.0, mainAxisPaintOffset));
      }
      child = childAfter(child);
    }
  }

  // hitTestChildren 保持不变
  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    RenderBox? child = lastChild;
    while (child != null) {
      if (hitTestBoxChild(
        BoxHitTestResult.wrap(result),
        child,
        mainAxisPosition: mainAxisPosition,
        crossAxisPosition: crossAxisPosition,
      )) {
        return true;
      }
      child = childBefore(child);
    }
    return false;
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    final parentData = child.parentData as SliverMultiBoxAdaptorParentData;
    return (parentData.layoutOffset ?? 0.0) - constraints.scrollOffset;
  }

  int indexOf(RenderBox child) {
    return (child.parentData as SliverMultiBoxAdaptorParentData).index ?? -1;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    // RenderSliverHelpers 提供的辅助方法
    // 它会自动调用我们实现的 childMainAxisPosition 来计算偏移
    applyPaintTransformForBoxChild(child as RenderBox, transform);
  }

  // [新增] 必须覆盖以下三个生命周期方法，以正确管理 _keepAliveBucket 中的 children

  // 生命周期管理：必须包含 bucket 中的节点
  @override
  void visitChildren(RenderObjectVisitor visitor) {
    super.visitChildren(visitor);
    _keepAliveBucket.values.forEach(visitor);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (var child in _keepAliveBucket.values) child.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    for (var child in _keepAliveBucket.values) child.detach();
  }
}
