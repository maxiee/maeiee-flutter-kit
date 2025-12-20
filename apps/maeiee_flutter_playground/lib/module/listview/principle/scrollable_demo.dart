import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class PureScrollableDemo extends StatelessWidget {
  const PureScrollableDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('纯 Scrollable 简易 ListView')),
      body: const Center(
        child: SizedBox(
          height: 300,
          width: 300,
          // 给它一个边框，方便看清滚动区域
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.fromBorderSide(
                BorderSide(color: Colors.blue, width: 2),
              ),
            ),
            child: MyCustomScrollable(),
          ),
        ),
      ),
    );
  }
}

class MyCustomScrollable extends StatelessWidget {
  const MyCustomScrollable({super.key});

  @override
  Widget build(BuildContext context) {
    // 直接使用 Scrollable 组件
    return Scrollable(
      // 1. 设置滚动方向
      axisDirection: AxisDirection.down,

      // 2. 视口构建器：这是 Scrollable 唯一要在乎的 UI 部分
      // context: 上下文
      // offset: 核心！这是 Scrollable 计算出的滚动位置
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        return MySimpleViewport(offset: offset);
      },
    );
  }
}

/// 一个极简的“视口”，它不使用复杂的 RenderViewport，
/// 而是简单地根据 offset 移动自己的孩子。
class MySimpleViewport extends StatelessWidget {
  final ViewportOffset offset;

  const MySimpleViewport({super.key, required this.offset});

  @override
  Widget build(BuildContext context) {
    // 3. 这是一个简易的实现，通常 Viewport 会更复杂。
    // 这里我们用 SingleChildScrollView 的原理：
    // 只是简单地根据 offset 偏移内容。

    return LayoutBuilder(
      builder: (context, constraints) {
        // 修复：必须告知 offset 内容的边界，否则 Scrollable 不知道能滚多远，
        // 且 minScrollExtent 为 null 会导致滚动时报错。
        // 假设内容高度是 1000 (20 * 50)
        final double contentHeight = 1000.0;
        final double viewportHeight = constraints.maxHeight;
        // 设置滚动范围：min=0, max=内容-视口
        offset.applyContentDimensions(0.0, contentHeight - viewportHeight);

        // 重点：我们需要监听 offset 的变化来重绘
        return AnimatedBuilder(
          animation: offset,
          builder: (context, child) {
            return Stack(
              children: [
                // 根据 offset.pixels 移动内容
                Positioned(
                  top: -offset.pixels,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: List.generate(20, (index) {
                      return Container(
                        height: 50,
                        color: index % 2 == 0
                            ? Colors.amber[100]
                            : Colors.amber[300],
                        alignment: Alignment.center,
                        child: Text('Item $index'),
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
