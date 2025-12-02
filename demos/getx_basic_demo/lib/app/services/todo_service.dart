import 'package:get/get.dart';
import 'package:getx_basic_demo/app/models/todo.dart';

enum TodoFilter { all, active, done }

class TodoService extends GetxService {
  final todos = <Todo>[].obs;

  final filter = TodoFilter.all.obs;

  // 计算属性
  List<Todo> get filteredTodos {
    switch (filter.value) {
      case TodoFilter.active:
        return todos.where((todo) => !todo.isDone).toList();
      case TodoFilter.done:
        return todos.where((todo) => todo.isDone).toList();
      case TodoFilter.all:
        return todos;
    }
  }

  void addTodo(Todo todo) {
    todos.add(todo);
  }

  void removeTodoById(String id) {
    todos.removeWhere((todo) => todo.id == id);
  }

  void toggleTodoById(String id) {
    final index = todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      todos[index].isDone = !todos[index].isDone;
      todos.refresh();
    }
  }

  Todo? getTodoById(String id) => todos.firstWhereOrNull((t) => t.id == id);
}
