import 'package:get/get.dart';
import 'package:my_life_rpg/controllers/session_controller.dart';

class SessionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SessionController());
  }
}
