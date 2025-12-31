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

  MyElement? childElement;

  @override
  void mount(MyElement? parent) {
    // 1. 【重要】必须调用 super，接收 owner
    super.mount(parent);

    // 2. 复用逻辑：挂载本质上就是“第一次重建”
    performRebuild();
  }

  @override
  void performRebuild() {
    // 1. 执行 build，获取各种下层 Widget 配置
    // 注意：此时 this.widget 已经是更新后的 widget 了（由 updateChild 赋值）
    final MyWidget builtWidget = (widget as MyStatelessWidget).build(this);

    // 2. 【核心】调用 updateChild
    // - 首次 mount 时：childElement 为 null，创建新 Element
    // - 更新时：childElement 不为 null，对比 builtWidget 类型，决定是更新还是重建
    childElement = updateChild(childElement, builtWidget);

    // 3. 向上交付 RenderObject
    // StatelessWidget 自己不产生 RenderObject，它仅仅是中间商
    // 它的 renderObject 指向的是它子树的 renderObject
    renderObject = childElement?.renderObject;
  }
}
