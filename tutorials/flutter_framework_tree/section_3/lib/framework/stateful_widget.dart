import 'package:section_1/framework/element.dart';
import 'package:section_1/framework/widget.dart';

abstract class MyStatefulWidget extends MyWidget {
  const MyStatefulWidget();

  @override
  MyElement createElement() => MyStatefulElement(this);

  // 工厂方法：创建 State
  MyState createState();
}

abstract class MyState<T extends MyStatefulWidget> {
  T get widget => _widget!;
  T? _widget;

  MyElement? _element; // State 持有 Element 的引用，以便调用 markNeedsBuild

  // 初始化方法
  void initState() {}

  // 这里的 setState 极其简化，只负责标记脏
  void setState(void Function() fn) {
    fn();
    _element!.markNeedsBuild(); // 核心：通知 Element 我变了
  }

  MyWidget build();
}

class MyStatefulElement extends MyElement {
  MyStatefulElement(MyStatefulWidget super.widget)
    : state = widget.createState();

  final MyState state;
  MyElement? childElement;

  @override
  void mount(MyElement? parent) {
    super.mount(parent);
    // 1. 建立关联
    state._element = this;
    state._widget = widget as MyStatefulWidget;

    // 2. 初始化 State
    state.initState();

    // 3. 执行第一次构建
    performRebuild();
  }

  @override
  void performRebuild() {
    // 1. 调用 State 的 build 方法获取子 Widget
    MyWidget built = state.build();

    // 2. 更新子 Element (Diff 算法)
    childElement = updateChild(childElement, built);

    // 3. 向上提供 RenderObject (自己没有，借用孩子的)
    renderObject = childElement?.renderObject;
  }
}
