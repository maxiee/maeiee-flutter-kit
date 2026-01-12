import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:maeiee_flutter_playground/module/listview/principle/sliver/simple_sliver_adapter.dart';

class SliverProtocolDemo extends StatelessWidget {
  const SliverProtocolDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sliver Protocol Demo')),
      body: Scrollable(
        axisDirection: AxisDirection.down,
        viewportBuilder: (BuildContext context, ViewportOffset offset) {
          return Viewport(
            offset: offset,
            // 这里使用了 Flutter 原生的 Viewport，它接受 slivers 数组
            slivers: [
              // 这是一个普通的 Box，通过我们的适配器变成 Sliver
              SimpleSliverAdapter(
                child: Container(
                  height: 150,
                  color: Colors.redAccent,
                  alignment: Alignment.center,
                  child: const Text(
                    'Header (Box)',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ),
              // 模拟一个列表，手动创建多个 Sliver
              for (int i = 0; i < 20; i++)
                SimpleSliverAdapter(
                  child: Container(
                    height: 60, // 每个 Item 高度固定
                    margin: const EdgeInsets.all(4),
                    color: Colors.primaries[i % Colors.primaries.length],
                    alignment: Alignment.center,
                    child: Text('Item $i'),
                  ),
                ),
              SimpleSliverAdapter(
                child: Container(
                  height: 100,
                  color: Colors.grey,
                  alignment: Alignment.center,
                  child: const Text(
                    'Footer',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
