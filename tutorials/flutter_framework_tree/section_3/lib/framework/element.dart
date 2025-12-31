import 'package:section_1/framework/build_owner.dart';
import 'package:section_1/framework/render_object.dart';
import 'package:section_1/framework/widget.dart';

abstract class MyElement {
  MyElement(this.widget);
  MyWidget widget;

  MyElement? parent;
  MyRenderObject? renderObject;

  MyBuildOwner? owner; // 引用 BuildOwner

  bool dirty = true; // 标记当前 Element 是否需要重建

  // 核心方法：将自己挂载到父节点下面
  // 挂载：从父节点接收 owner
  void mount(MyElement? parent) {
    this.parent = parent;
    if (parent != null) {
      owner = parent.owner;
    }
  }

  // 标记为脏，请求 BuildOwner 调度重建
  void markNeedsBuild() {
    dirty = true;
    owner?.scheduleBuildFor(this);
  }

  // 执行重建
  void rebuild() {
    dirty = false;
    performRebuild();
  }

  // 子类实现具体的重建逻辑
  void performRebuild();

  // 【核心 Diff 算法】：对比新旧 Widget，决定如何更新子 Element
  // 核心方法：给定一个 Widget，将其转换为 Element
  // 如果是第一次见（child 为空），就创建它
  MyElement? updateChild(MyElement? child, MyWidget? newWidget) {
    // 1. 判空：如果没有新的 Widget 配置，说明这里不需要显示任何东西，直接返回 null
    if (newWidget == null) return null;

    if (child != null && child.widget.runtimeType == newWidget.runtimeType) {
      // 2. 类型一致，复用 Element，只更新 Widget 配置
      child.widget = newWidget;
      child.performRebuild(); // 递归更新子树
      return child;
    }

    // 3. 类型不一致（或 child 为空），创建新 Element
    // (此处应 unmount 旧 child，简化版暂略)
    final newChild = newWidget.createElement();
    newChild.mount(this);
    return newChild;
  }
}
