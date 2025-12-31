// Widget：组合类组件基类
import 'package:section_1/framework/element.dart';
import 'package:section_1/framework/widget.dart';

abstract class MyStatelessWidget extends MyWidget {
  const MyStatelessWidget();

  @override
  MyElement createElement() => MyStatelessElement(this);

  // 留给子类实现：描述我长什么样
  MyWidget build(MyElement context);
}

// Element：负责执行 build 的管家
class MyStatelessElement extends MyElement {
  MyStatelessElement(MyStatelessWidget super.widget);

  late MyElement childElement;

  @override
  void mount(MyElement? parent) {
    this.parent = parent;

    // 1. 调用 Widget 的 build 方法，拿到“下一层” Widget
    final MyWidget builtWidget = (widget as MyStatelessWidget).build(this);

    // 2. 递归：把下一层 Widget 转换成 Element
    childElement = updateChild(null, builtWidget)!;

    // 3. 【关键点】：StatelessElement 自己没有 RenderObject，
    // 它直接借用子节点的 RenderObject 向上交付
    renderObject = childElement.renderObject;
  }
}
