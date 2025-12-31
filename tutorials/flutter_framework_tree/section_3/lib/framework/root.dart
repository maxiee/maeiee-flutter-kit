// 对应源码中的 RenderView
import 'dart:ui' as ui;

import 'package:section_1/framework/element.dart';
import 'package:section_1/framework/render_object.dart';
import 'package:section_1/framework/widget.dart';

class MyRenderView extends MyRenderObject {
  MyRenderObject? child;

  @override
  void paint(ui.Canvas canvas) {
    print("MyRenderView: 开始绘制，子节点状态为: ${child != null ? '存在' : '为空!'}");
    child?.paint(canvas);
  }
}

class MyRootWidget extends MyWidget {
  final MyWidget child;
  const MyRootWidget(this.child);
  @override
  MyElement createElement() => MyRootElement(this);
}

// 对应源码中的 RootElement
class MyRootElement extends MyElement {
  MyRootElement(super.widget);
  late MyElement childElement;

  @override
  void mount(MyElement? parent) {
    // 1. 【重要】调用 super，接收父级传递的 owner (根节点虽然 parent 为 null，但 owner 会手动赋值)
    super.mount(parent);

    // 1. 创建根渲染对象
    final renderView = MyRenderView();
    renderObject = renderView;

    // 2. 创建根渲染对象
    childElement = (widget as MyRootWidget).child.createElement();
    childElement.mount(this);

    // 3. 构建子 Element
    // 使用 updateChild 来处理初始化逻辑，虽然这里 child 为 null，
    // 但 updateChild 会处理新建逻辑，这样 mount 和 performRebuild 逻辑更统一
    childElement = updateChild(null, (widget as MyRootWidget).child)!;

    // 4. 连接渲染树
    renderView.child = childElement.renderObject;

    print(
      "MyRootElement: 已完成挂载，连接子渲染对象: ${childElement.renderObject.runtimeType}",
    );
  }

  @override
  void performRebuild() {
    // 1. 获取当前 Widget 中的子 Widget 配置
    // (在极简版中，MyRootWidget 通常是不变的，但为了架构完整性，我们依然走标准流程)
    final newWidget = (widget as MyRootWidget).child;

    // 2. 【核心】调用 updateChild 更新子节点
    // 这会触发子节点的 Diff 算法：
    // - 如果子节点是 StatelessWidget/StatefulWidget，会调用它们的 build
    // - 如果子节点类型变了，会销毁重建
    childElement = updateChild(childElement, newWidget)!;

    // 3. 重新连接渲染对象
    // 如果子 Element 复用了，renderObject 通常没变
    // 如果子 Element 重建了，renderObject 也会是新的，需要重新赋值给 renderView
    (renderObject as MyRenderView).child = childElement.renderObject;
  }
}
