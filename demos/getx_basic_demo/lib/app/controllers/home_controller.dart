import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/todo.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HomeController());
  }
}

class HomeController extends GetxController {
  final todos = <Todo>[].obs;
  final titleController = TextEditingController();
  final descController = TextEditingController();

  void addTodo() {
    if (titleController.text.isEmpty) return;
    todos.add(
      Todo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: titleController.text,
        description: descController.text,
      ),
    );
    titleController.clear();
    descController.clear();
    Get.back();
  }

  void toggleTodo(String id) {
    final index = todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      todos[index].isDone = !todos[index].isDone;
      todos.refresh();
    }
  }

  void deleteTodo(String id) => todos.removeWhere((t) => t.id == id);

  void showAddDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('添加待办'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '标题'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: '描述'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('取消')),
          TextButton(onPressed: addTodo, child: const Text('添加')),
        ],
      ),
    );
  }

  @override
  void onClose() {
    titleController.dispose();
    descController.dispose();
    super.onClose();
  }
}
