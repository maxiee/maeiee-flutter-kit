import 'package:flutter/material.dart';
import 'package:maeiee_flutter_playground/module/listview/principle/lazy_sliver_v2/lazy_list_keep_alive.dart';
import 'package:maeiee_flutter_playground/module/listview/principle/lazy_sliver_v2/lazy_sliver_list_v2.dart';

class AdvancedLazySliverDemo extends StatelessWidget {
  const AdvancedLazySliverDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KeepAlive & Cache Demo')),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SizedBox(height: 50, child: Center(child: Text("Start"))),
          ),
          LazySliverListV2(
            itemCount: 100,
            itemExtent: 60.0,
            cacheExtent: 150.0, // 【特性1】设置缓存区 150px (约 2.5 个 item)
            builder: (context, index) {
              print('Building item $index'); // 观察控制台，看看预加载了多少

              Widget item = Container(
                margin: const EdgeInsets.all(4),
                color: Colors.primaries[index % Colors.primaries.length]
                    .withOpacity(0.2),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    Text('Item $index '),
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(hintText: '输入内容测试状态保持'),
                      ),
                    ),
                    if (index % 2 == 0)
                      const Icon(Icons.lock, color: Colors.green, size: 16),
                  ],
                ),
              );

              // 【特性2】偶数项开启 KeepAlive
              if (index % 2 == 0) {
                return KeepAliveWrapper(keepAlive: true, child: item);
              } else {
                return item;
              }
            },
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 50, child: Center(child: Text("End"))),
          ),
        ],
      ),
    );
  }
}
