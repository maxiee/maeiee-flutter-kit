import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../widgets/todo_list_item.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Todo List')),
      body: Obx(
        () => c.todos.isEmpty
            ? const Center(child: Text('暂无待办事项'))
            : ListView.builder(
                itemCount: c.todos.length,
                itemBuilder: (_, i) => TodoListItem(
                  todo: c.todos[i],
                  onToggle: () => c.toggleTodo(c.todos[i].id),
                  onDelete: () => c.deleteTodo(c.todos[i].id),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: c.showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
