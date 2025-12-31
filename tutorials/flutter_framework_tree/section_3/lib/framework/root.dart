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

// 对应源码中的 RootElement
class MyRootElement extends MyElement {
  MyRootElement(super.widget);
  late MyElement childElement;

  @override
  void mount(MyElement? parent) {
    // 1. 创建根渲染对象
    final renderView = MyRenderView();
    renderObject = renderView;

    // 2. 创建并挂载子 Element
    childElement = (widget as MyRootWidget).child.createElement();
    childElement.mount(this);

    // 3. 【核心连接点】：将子渲染对象连接给根渲染对象
    renderView.child = childElement.renderObject;

    print(
      "MyRootElement: 已完成挂载，连接子渲染对象: ${childElement.renderObject.runtimeType}",
    );
  }
}

class MyRootWidget extends MyWidget {
  final MyWidget child;
  const MyRootWidget(this.child);
  @override
  MyElement createElement() => MyRootElement(this);
}
