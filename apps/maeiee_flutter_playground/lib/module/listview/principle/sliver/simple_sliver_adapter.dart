// ---------------------------------------------------------------------------
// 1. Widget 层：定义一个 SingleChildRenderObjectWidget
// ---------------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SimpleSliverAdapter extends SingleChildRenderObjectWidget {
  const SimpleSliverAdapter({super.key, required Widget child})
    : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSimpleSliverAdapter();
  }
}

// ---------------------------------------------------------------------------
// 2. RenderObject 层：核心实现
// ---------------------------------------------------------------------------
class RenderSimpleSliverAdapter extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox>, RenderSliverHelpers {
  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData) {
      child.parentData = SliverPhysicalParentData();
    }
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    // 告诉系统，子组件在主轴上的逻辑位置。
    // 因为我们是普通的列表项，如果 Sliver 被滚上去一部分（scrollOffset），
    // 子组件的起始位置相对于 Sliver 的可视原点就是负的 scrollOffset。
    return -constraints.scrollOffset;
  }

  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }
    // 获取来自 Viewport 的约束
    final SliverConstraints constraints = this.constraints;

    // A. 布局子 Box
    // 在 Sliver 中，主轴通常是无限延伸的，所以我们将 Box 的主轴约束设为无限大
    // 交叉轴（宽度）则强制填满
    child!.layout(constraints.asBoxConstraints(), parentUsesSize: true);

    final double childExtent = child!.size.height; // 假设垂直滚动

    // B. 计算绘制高度 (paintExtent)
    // 算法：看看总高度减去已经滚出去的部分，还剩多少。
    // 同时，不能超过 child 的实际高度，也不能超过视口剩余的空间。
    final double paintedChildSize = calculatePaintOffset(
      constraints,
      from: 0.0,
      to: childExtent,
    );

    // C. 计算缓存区域 (这里简化处理，直接等于绘制区域)
    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: 0.0,
      to: childExtent,
    );

    // D. 设置 Geometry
    geometry = SliverGeometry(
      // 告诉 Viewport 我原本有多高（用于计算滚动条和总长度）
      scrollExtent: childExtent, // 真实高度
      // 告诉 Viewport 我现在画多高（用于屏幕显示）
      paintExtent: paintedChildSize, // 可见高度
      maxPaintExtent: childExtent,
      layoutExtent: paintedChildSize, // 布局占据的高度
      cacheExtent: cacheExtent,
      hitTestExtent: paintedChildSize,
      // 如果子组件还有部分内容在视口外，或者已经滚出去了，可以标记为有溢出
      hasVisualOverflow:
          childExtent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0.0,
    );

    // E. 设定子 Box 的绘制偏移
    // 如果 scrollOffset > 0，说明这个 Sliver 已经往上滚了一部分，
    // 我们需要把子 Box 往上移动，产生“滚动”的视觉效果。
    if (child != null) {
      final SliverPhysicalParentData childParentData =
          child!.parentData! as SliverPhysicalParentData;
      // 这里简化了 axisDirection 的判断，默认向下滚动
      // geometry!.paintExtent 是当前可见高度
      // childExtent 是实际高度
      // 这里的逻辑：当滚动发生时，Box 需要反向移动以保持视觉静止或随滚动移动
      // 对于简单的 Adapter，通常是：
      // paintOffset = -constraints.scrollOffset
      switch (constraints.axisDirection) {
        case AxisDirection.down:
          childParentData.paintOffset = Offset(0.0, -constraints.scrollOffset);
          break;
        case AxisDirection.right:
          childParentData.paintOffset = Offset(-constraints.scrollOffset, 0.0);
          break;
        default:
          break;
      }
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && geometry!.visible) {
      final SliverPhysicalParentData childParentData =
          child!.parentData! as SliverPhysicalParentData;
      // offset 是 Viewport 给 Sliver 的原点
      // childParentData.paintOffset 是我们刚才算的内部偏移
      context.paintChild(child!, offset + childParentData.paintOffset);
    }
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    if (child != null) {
      // 这是一个 Helper 方法，帮助把 Sliver 的点击坐标转换为 Box 的点击坐标
      return hitTestBoxChild(
        BoxHitTestResult.wrap(result),
        child!,
        mainAxisPosition: mainAxisPosition,
        crossAxisPosition: crossAxisPosition,
      );
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final SliverPhysicalParentData childParentData =
        child.parentData! as SliverPhysicalParentData;
    childParentData.applyPaintTransform(transform);
  }
}
