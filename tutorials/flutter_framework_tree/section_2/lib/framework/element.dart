import 'package:section_1/framework/render_object.dart';
import 'package:section_1/framework/widget.dart';

abstract class MyElement {
  MyElement(this.widget);
  final MyWidget widget;

  MyElement? parent;
  MyRenderObject? renderObject;

  // 核心方法：将自己挂载到父节点下面
  void mount(MyElement? parent);

  // 核心方法：给定一个 Widget，将其转换为 Element
  // 如果是第一次见（child 为空），就创建它
  MyElement? updateChild(MyElement? child, MyWidget? newWidget) {
    // 1. 判空：如果没有新的 Widget 配置，说明这里不需要显示任何东西，直接返回 null
    if (newWidget == null) return null;

    // 2. 生产：调用 Widget 的工厂方法，生产出对应的 Element 实例
    //    Widget 只是图纸，Element 才是真正干活的管家
    final MyElement newChild = newWidget.createElement();

    // 3. 挂载：将新创建的 Element 挂载到当前 Element (this) 下面
    //    这一步非常关键，它建立了 Element 树的父子关系
    //    在 MyRenderObjectElement 中，mount 还会触发 createRenderObject()
    newChild.mount(this); // 递归挂载
    return newChild;
  }
}
