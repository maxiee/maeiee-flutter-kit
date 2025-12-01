import 'package:flutter/material.dart';
import '../../models/todo.dart';

class TodoListItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const TodoListItem({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Checkbox(value: todo.isDone, onChanged: (_) => onToggle()),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.isDone ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: todo.description.isNotEmpty ? Text(todo.description) : null,
      trailing: IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
    );
  }
}
