import 'package:get/get.dart';
import 'package:my_life_rpg/controllers/home_controller.dart';
import 'package:my_life_rpg/controllers/matrix_controller.dart';
import 'package:my_life_rpg/controllers/mission_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // 使用 lazyPut，只有当 View 第一次 find 时才创建实例
    // fenix: true 表示如果 Controller 被 dispose 了，下次 find 时会重建
    // 对于常驻首页的控制器，fenix 其实不是必须的，但是个好习惯

    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => MissionController());
    Get.lazyPut(() => MatrixController());
  }
}
