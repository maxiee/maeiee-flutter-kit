import 'package:get/get.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';

class DetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(DetailController());
  }
}

class DetailController extends GetxController {
  final todo = Rxn<Todo>();

  @override
  void onInit() {
    super.onInit();
    final id = Get.parameters['id'];
    if (id != null) {
      todo.value = Get.find<TodoService>().getTodoById(id);
    }
  }
}
