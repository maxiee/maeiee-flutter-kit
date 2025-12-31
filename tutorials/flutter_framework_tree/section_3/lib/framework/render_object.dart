import 'dart:ui' as ui;

abstract class MyRenderObject {
  // 极简版绘制接口，由渲染树调用
  void paint(ui.Canvas canvas);
}
