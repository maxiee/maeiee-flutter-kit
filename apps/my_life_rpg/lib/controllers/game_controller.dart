import 'package:get/get.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import 'package:my_life_rpg/services/time_service.dart';

class GameController extends GetxController {
  // 服务定位器
  final QuestService questService = Get.put(QuestService());
  final TimeService timeService = Get.put(TimeService());

  @override
  void onInit() {
    super.onInit();

    // 加载 Mock 数据 (委托给 Service)
    questService.loadMockData();
  }
}
