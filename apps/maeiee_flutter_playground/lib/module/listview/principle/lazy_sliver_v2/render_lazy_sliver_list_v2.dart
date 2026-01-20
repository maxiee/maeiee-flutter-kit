import 'package:flutter/rendering.dart';
import 'package:maeiee_flutter_playground/module/listview/principle/lazy_sliver_v2/lazy_list_keep_alive.dart';

class RenderLazySliverListV2 extends RenderSliver
    with
        ContainerRenderObjectMixin<RenderBox, SliverMultiBoxAdaptorParentData>,
        RenderSliverHelpers {
  final RenderSliverBoxChildManager childManager;
  double itemExtent;
  double cacheExtent;

  final Map<int, RenderBox> _keepAliveBucket = {};

  RenderLazySliverListV2({
    required this.childManager,
    required this.itemExtent,
    required this.cacheExtent,
  });

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverKeepAliveParentData) {
      child.parentData = SliverKeepAliveParentData();
    }
  }

  // 1. 修复点击报错：处理坐标转换
  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    applyPaintTransformForBoxChild(child as RenderBox, transform);
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

    // --- GC 阶段 ---
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

    for (var child in childrenToRemove) {
      final parentData = child.parentData as SliverKeepAliveParentData;
      if (parentData.keepAlive) {
        // 【关键修复 A】：入袋时也要保护 ParentData
        // 1. 备份数据
        final int index = parentData.index!;
        final bool wasKeepAlive = parentData.keepAlive;

        // 【关键修复点 A】：所有结构变更操作必须都在 callback 内部
        invokeLayoutCallback((c) {
          // 1. 从链表移除 (child 变为 detached)
          remove(child);
          // 2. 存入口袋
          _keepAliveBucket[parentData.index!] = child;
          // 3. 手动认领 (child 变为 attached，但不在链表中)
          // 这一步如果不放在 callback 里，就会报 "mutated in performLayout"
          adoptChild(child);

          // 5. 恢复数据！(否则下次复活时 keepAlive 就是 false 了)
          final newData = child.parentData as SliverKeepAliveParentData;
          newData.keepAlive = wasKeepAlive;
          newData.index = index;
        });
      } else {
        invokeLayoutCallback((c) {
          childManager.removeChild(child);
        });
      }
    }

    // --- 构建阶段 ---
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

      if (child == null) {
        if (_keepAliveBucket.containsKey(index)) {
          child = _keepAliveBucket.remove(index)!;

          // 1. 备份 ParentData 信息
          final SliverKeepAliveParentData oldParentData =
              child.parentData as SliverKeepAliveParentData;
          // 备份关键状态（如果有其他自定义字段也要备份）
          final bool wasKeepAlive = oldParentData.keepAlive;

          // 3. 重新插入链表（此时会创建新的 ParentData，keepAlive 默认为 false）
          invokeLayoutCallback((c) {
            // 2. 解除认领（此时 child.parentData 会被置为 null）
            dropChild(child!);

            insert(child, after: _findChildByIndex(index - 1));

            // 4. 【关键】恢复 ParentData 状态
            final SliverKeepAliveParentData newParentData =
                child.parentData as SliverKeepAliveParentData;
            newParentData.keepAlive = wasKeepAlive;
          });
        } else {
          // 新建
          invokeLayoutCallback((c) {
            RenderBox? anchor = _findChildByIndex(index - 1);
            childManager.createChild(index, after: anchor);
          });
          // 找回新节点
          RenderBox? anchor = _findChildByIndex(index - 1);
          if (anchor != null) {
            child = childAfter(anchor);
          } else {
            child = firstChild;
          }
        }
      }

      // 布局
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

  // --- 辅助与生命周期 ---

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

  // 【关键修复 C】：必须正确管理口袋中节点的生命周期
  @override
  void visitChildren(RenderObjectVisitor visitor) {
    super.visitChildren(visitor); // 访问链表中的节点
    _keepAliveBucket.values.forEach(visitor); // 访问口袋中的节点
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (var child in _keepAliveBucket.values) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    for (var child in _keepAliveBucket.values) {
      child.detach();
    }
  }

  // 【修复列表跳回顶部的 Bug】
  // 必须告诉 Viewport 每个 child 实际的滚动位置，否则 showOnScreen 会误以为 child 在 0.0 处
  @override
  double? childScrollOffset(RenderObject child) {
    final parentData = child.parentData as SliverMultiBoxAdaptorParentData;

    // 1. 优先返回实际布局偏移
    if (parentData.layoutOffset != null) {
      return parentData.layoutOffset;
    }

    // 2. [兜底逻辑] 如果 layoutOffset 尚未计算（极其罕见），
    // 使用 index * itemExtent 预估正确位置。
    // 这样既防止了返回 null 导致的 Crash，也防止了返回 0.0 导致的跳回顶部 Bug。
    if (parentData.index != null) {
      return parentData.index! * itemExtent;
    }

    // 3. 实在没办法了，只能返回 0.0
    return 0.0;
  }
}
