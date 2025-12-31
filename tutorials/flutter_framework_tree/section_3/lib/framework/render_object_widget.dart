// Widget：渲染类组件基类
import 'package:section_1/framework/element.dart';
import 'package:section_1/framework/render_object.dart';
import 'package:section_1/framework/widget.dart';

abstract class MyRenderObjectWidget extends MyWidget {
  const MyRenderObjectWidget();

  @override
  MyElement createElement() => MyRenderObjectElement(this);

  // 留给子类实现：创建真正的干活的人
  MyRenderObject createRenderObject();
}

// Element：负责管理渲染对象的管家
class MyRenderObjectElement extends MyElement {
  MyRenderObjectElement(super.widget);

  @override
  void mount(MyElement? parent) {
    this.parent = parent;
    // 1. 创建属于自己的 RenderObject
    renderObject = (widget as MyRenderObjectWidget).createRenderObject();

    // 渲染类组件通常是叶子节点或容器节点，这里我们先保持极简，不处理它的 child
  }
}
