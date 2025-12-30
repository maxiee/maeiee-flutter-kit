import 'package:section_1/framework/render_object.dart';
import 'package:section_1/framework/widget.dart';

abstract class MyElement {
  MyElement(this.widget);
  final MyWidget widget;

  MyElement? parent;
  MyRenderObject? renderObject;

  // 将 Element 挂载到树上
  void mount(MyElement? parent) {
    this.parent = parent;
  }
}
