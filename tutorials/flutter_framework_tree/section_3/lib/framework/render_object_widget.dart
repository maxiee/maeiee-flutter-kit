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

  // 新增：用于更新 RenderObject 属性
  void updateRenderObject(MyRenderObject renderObject);
}

// Element：负责管理渲染对象的管家
class MyRenderObjectElement extends MyElement {
  MyRenderObjectElement(super.widget);

  @override
  void mount(MyElement? parent) {
    super.mount(parent);
    // 1. 创建属于自己的 RenderObject
    renderObject = (widget as MyRenderObjectWidget).createRenderObject();
  }

  @override
  void performRebuild() {
    // 当 Element 重建时，调用 widget 的 update 方法更新 renderObject
    (widget as MyRenderObjectWidget).updateRenderObject(renderObject!);
  }
}
