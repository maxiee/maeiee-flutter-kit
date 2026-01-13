import 'package:flutter/material.dart';
import 'package:maeiee_flutter_playground/module/listview/principle/lazy_sliver/lazy_sliver_list.dart';

class LazySliverDemo extends StatelessWidget {
  const LazySliverDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lazy Loading Sliver Demo')),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: Center(child: Text("Header (SliverToBoxAdapter)")),
            ),
          ),
          // 使用我们自定义的懒加载列表
          LazySliverList(
            itemCount: 1000, // 1000 个数据
            itemExtent: 60.0, // 固定高度 60
            builder: (context, index) {
              // 【关键验证点】观察控制台，只有进入屏幕的 item 才会打印
              print('Building item $index');
              return Container(
                alignment: Alignment.center,
                //以此证明确实是按需创建
                color: Colors.primaries[index % Colors.primaries.length]
                    .withOpacity(0.2),
                child: Text(
                  'Lazy Item $index',
                  style: const TextStyle(fontSize: 16),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: Center(child: Text("Footer (SliverToBoxAdapter)")),
            ),
          ),
        ],
      ),
    );
  }
}
