import 'dart:ui' as ui;

import 'package:section_1/framework/element.dart';
import 'package:section_1/framework/render_object.dart';
import 'package:section_1/framework/render_object_widget.dart';
import 'package:section_1/framework/root.dart';
import 'package:section_1/framework/stateless_widget.dart';
import 'package:section_1/framework/widget.dart';

// ===================== 自定义 Widget 实现 =====================

// Widget：描述一个带颜色的盒子
class MyColoredBoxWidget extends MyRenderObjectWidget {
  final ui.Color color;
  const MyColoredBoxWidget(this.color);

  @override
  MyRenderObject createRenderObject() => MyColoredBoxRenderObject(color);
}

// RenderObject：执行真正的 Canvas 绘制
class MyColoredBoxRenderObject extends MyRenderObject {
  final ui.Color color;
  MyColoredBoxRenderObject(this.color);

  @override
  void paint(ui.Canvas canvas) {
    final paint = ui.Paint()..color = color;
    // 画一个边框，防止颜色和背景太接近
    final borderPaint = ui.Paint()
      ..color = ui.Color(0xFF000000)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = ui.Rect.fromLTWH(100, 100, 200, 200);
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);
    print("Red Square is painting at $rect");
  }
}

class MyComplexBox extends MyStatelessWidget {
  @override
  MyWidget build(MyElement context) {
    // 这里体现了“组合”：ComplexBox 包装了 ColoredBox
    return MyColoredBoxWidget(ui.Color(0xFF00FF00)); // 改成绿色的方块
  }
}

void main() {
  // 构建一棵 Widget 树
  // 根组件中包裹我们的方块组件
  final widgetTree = MyRootWidget(MyComplexBox());

  // 根据 Widget 树构建一棵 Element 树（并自动生成 RenderObject 树）
  // 这个过程模拟了源码中的 attachRootWidget()
  final rootElement = widgetTree.createElement();
  rootElement.mount(null);

  // 注册引擎的“每一帧绘制”回调
  // 这部分模拟了 RendererBinding 中的 drawFrame() 逻辑
  ui.PlatformDispatcher.instance.onDrawFrame = () {
    // FlutterView 是 dart:ui 库中的一个核心类，它代表了 Flutter 应用可以绘制内容的“视图”或“窗口”。
    // 它扮演了连接你的渲染逻辑和底层屏幕的关键角色。
    final ui.FlutterView view = ui.PlatformDispatcher.instance.implicitView!;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);

    // 画白底
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, view.physicalSize.width, view.physicalSize.height),
      ui.Paint()..color = ui.Color(0xFFFFFFFF),
    );

    // 绘制三棵树
    // 因为已经 scale 过了，rootElement 里的 100, 100 坐标现在是逻辑坐标了
    rootElement.renderObject!.paint(canvas);

    // 提交渲染 (上屏)
    final ui.Picture picture = recorder.endRecording();
    final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
    sceneBuilder.addPicture(ui.Offset.zero, picture);
    // 将构建好的场景（Scene）提交给视图进行渲染
    view.render(sceneBuilder.build());
  };

  // 告诉引擎：我们需要画画，请在下一帧信号到来时叫我
  ui.PlatformDispatcher.instance.scheduleFrame();

  print("极简 Flutter 三棵树已成功运行于屏幕！");
}
