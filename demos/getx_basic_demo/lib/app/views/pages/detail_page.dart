import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/detail_controller.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DetailController>();
    return Scaffold(
      appBar: AppBar(title: const Text('待办详情')),
      body: Obx(() {
        final todo = c.todo.value;
        if (todo == null) return const Center(child: Text('未找到该待办'));
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                todo.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(todo.description.isEmpty ? '无描述' : todo.description),
              const SizedBox(height: 16),
              Text('状态: ${todo.isDone ? "已完成" : "未完成"}'),
              Text('创建时间: ${todo.createdAt}'),
            ],
          ),
        );
      }),
    );
  }
}
