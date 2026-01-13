import 'package:flutter/rendering.dart';

class RenderLazySliverList extends RenderSliver
    with
        ContainerRenderObjectMixin<RenderBox, SliverMultiBoxAdaptorParentData>,
        RenderSliverHelpers {
  final RenderSliverBoxChildManager childManager;
  double itemExtent; // 每个 Item 的固定高度

  RenderLazySliverList({required this.childManager, required this.itemExtent});

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout(); // [规范] 通知 Manager 布局开始
    childManager.setDidUnderflow(false);

    // scrollOffset: 也就是我们已经滚过去的距离（相对于 Sliver 顶部）
    // cacheOrigin: 缓存区的起始点，通常为负数（向上预加载）或 0
    final double scrollOffset =
        constraints.scrollOffset + constraints.cacheOrigin;

    // visibleHeight: 视口高度 + 缓存区高度
    final double visibleHeight =
        constraints.remainingPaintExtent + constraints.remainingCacheExtent;

    // 1. [数学计算] 计算当前视口覆盖的 item 索引范围
    final int firstIndex = (scrollOffset / itemExtent).floor();
    final int lastIndex = ((scrollOffset + visibleHeight) / itemExtent).ceil();

    // 确保索引不越界
    final int targetFirstIndex = firstIndex.clamp(
      0,
      childManager.childCount - 1,
    );
    final int targetLastIndex = lastIndex.clamp(0, childManager.childCount - 1);

    // 2. [垃圾回收 GC]
    // 遍历当前持有的所有 RenderBox，如果其 index 不在 [targetFirstIndex, targetLastIndex] 范围内，则移除。
    // 注意：必须先收集再移除，不能在遍历链表时直接修改链表结构。
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

    // 使用 invokeLayoutCallback 包裹移除操作
    // 通知 Manager 销毁这些节点 (Element unmount -> RenderBox detach)
    if (childrenToRemove.isNotEmpty) {
      invokeLayoutCallback((SliverConstraints c) {
        for (var child in childrenToRemove) {
          childManager.removeChild(child);
        }
      });
    }

    // 3. [按需创建 & 布局]
    // 我们需要确保 targetFirstIndex 到 targetLastIndex 的所有孩子都存在且已布局

    // 为了防止链表操作混乱，我们按顺序处理。
    // 我们维护一个 "当前正在处理的链表节点" 指针。
    RenderBox? currentChild = firstChild;

    for (int index = targetFirstIndex; index <= targetLastIndex; index++) {
      // 1. 尝试找到当前 index 对应的 child
      // 因为我们已经 GC 了头部和尾部，理论上链表里的节点应该都在可视范围内。
      // 如果链表是连续的，currentChild 应该就是我们要找的 index。
      // 但为了健壮性，我们还是做个判断。

      RenderBox? child;

      // 这里的逻辑：寻找是否有现成的 child 对应这个 index
      // 注意：这里我们简化了查找逻辑，假设如果 currentChild 存在，它应该就是 index
      // 如果不是，说明中间有断层（缺页），需要创建。

      if (currentChild != null) {
        final parentData =
            currentChild.parentData as SliverMultiBoxAdaptorParentData;
        if (parentData.index == index) {
          child = currentChild;
          currentChild = childAfter(currentChild); // 指针后移
        }
      }

      // 2. 如果没找到，创建它
      if (child == null) {
        invokeLayoutCallback((SliverConstraints c) {
          // 插入位置：
          // 如果当前有 firstChild，且 index < firstChild.index，说明是往头部补。
          // 如果是往尾部补，after 应该是链表最后一个。
          // 这里的逻辑对于初学者稍显复杂，为了保证绝对稳健，我们使用 _findChildByIndex 的变体

          // 查找锚点：找 index - 1
          RenderBox? anchor = _findChildByIndex(index - 1);
          childManager.createChild(index, after: anchor);
        });

        // [关键] 创建完立刻找回。
        // 此时，虽然 layout 还没跑，但对象已经插入链表。
        // 但是！它的 parentData.index 可能还没被设置（取决于 Element.insertRenderObjectChild 实现）
        // 我们的 _findChildByIndex 依赖 parentData.index。这造成了死锁。

        // 解决办法：我们不依赖 index 查找，而是依赖链表位置查找。
        // 如果我们刚刚在 anchor 后面插入了新节点，那 anchor 的 childAfter 就是新节点。
        RenderBox? anchor = _findChildByIndex(index - 1);
        if (anchor != null) {
          child = childAfter(anchor);
        } else {
          // 如果 anchor 为空，说明 index=0 或者前面没有节点，新节点应该是 firstChild
          child = firstChild;
        }
      }

      // 3. 布局
      if (child != null) {
        // [关键] 必须先设置 index，否则下次循环 _findChildByIndex 会失败
        final parentData = child.parentData as SliverMultiBoxAdaptorParentData;
        parentData.index = index;
        parentData.layoutOffset = index * itemExtent;

        child.layout(
          constraints.asBoxConstraints(
            minExtent: itemExtent,
            maxExtent: itemExtent,
          ),
        );
      } else {
        // 理论上不应该到这里，除非 createChild 失败
      }
    }

    // 4. [提交几何信息]
    final double totalHeight = childManager.childCount * itemExtent;

    geometry = SliverGeometry(
      scrollExtent: totalHeight,
      // 计算实际绘制的大小：(总高度 - 滚过去的距离) 限制在 0 到 remainingPaintExtent 之间
      paintExtent: calculatePaintOffset(
        constraints,
        from: 0.0,
        to: totalHeight,
      ),
      maxPaintExtent: totalHeight,
    );

    childManager.didFinishLayout(); // [规范] 通知 Manager 布局结束
  }

  // 辅助方法：在子节点链表中查找指定 index 的 RenderBox
  // 在生产级实现中（如 RenderSliverList），这通常通过缓存或从 firstChild 推断来优化，避免 O(N) 查找。
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
      // 手动计算绘制坐标
      // 物理坐标 Y = 列表顶部Offset + (Item逻辑位置 - 当前滚动量)
      if (parentData.index != null && parentData.layoutOffset != null) {
        final double childLayoutOffset = parentData.layoutOffset!;
        final double mainAxisPaintOffset =
            childLayoutOffset - constraints.scrollOffset;

        // 根据滚动方向处理 (简化为仅处理垂直向下)
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
    RenderBox? child = lastChild; // 点击测试通常从后往前（Z轴由上到下）
    while (child != null) {
      // hitTestBoxChild 是 RenderSliverHelpers 提供的工具方法，处理坐标转换
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

  // 必须重写此方法，RenderSliverHelpers 的 hitTestBoxChild 依赖它
  // 返回 child 在主轴上相对于 Sliver 可视顶部的位置
  @override
  double childMainAxisPosition(RenderBox child) {
    final parentData = child.parentData as SliverMultiBoxAdaptorParentData;
    return (parentData.layoutOffset ?? 0.0) - constraints.scrollOffset;
  }

  // 用于获取子节点的 index，用于 Manager 回收
  int indexOf(RenderBox child) {
    return (child.parentData as SliverMultiBoxAdaptorParentData).index ?? -1;
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverMultiBoxAdaptorParentData) {
      child.parentData = SliverMultiBoxAdaptorParentData();
    }
  }
}
