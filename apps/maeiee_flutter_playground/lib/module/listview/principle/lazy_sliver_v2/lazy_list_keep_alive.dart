import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:maeiee_flutter_playground/module/listview/principle/lazy_sliver_v2/lazy_sliver_list_v2.dart';
import 'package:maeiee_flutter_playground/module/listview/principle/lazy_sliver_v2/render_lazy_sliver_list_v2.dart';

class KeepAliveWrapper extends ParentDataWidget<SliverKeepAliveParentData> {
  final bool keepAlive;

  const KeepAliveWrapper({
    super.key,
    required this.keepAlive,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData as SliverKeepAliveParentData;
    if (parentData.keepAlive != keepAlive) {
      parentData.keepAlive = keepAlive;
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => LazySliverListV2;
}

// [新增] 必须定义这个 ParentData，用于承载 keepAlive 标记
class SliverKeepAliveParentData extends SliverMultiBoxAdaptorParentData {
  bool keepAlive = false;
  @override
  String toString() => '${super.toString()}, keepAlive=$keepAlive';
}
