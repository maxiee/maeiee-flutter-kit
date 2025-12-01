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
}
