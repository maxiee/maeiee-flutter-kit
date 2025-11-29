import 'package:get/get.dart';
import 'package:my_life_rpg/core/data/project_repository.dart';
import 'package:my_life_rpg/core/data/quest_repository.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import 'package:my_life_rpg/services/time_service.dart';

/// [InitialBinding]
/// 应用全局依赖注入配置。
/// 在 main.dart 中加载，确保 App 启动时核心服务就绪。
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 1. 底层仓储 (Data Layer)
    // 使用 permanent: true 确保它们不会被内存回收
    Get.put(ProjectRepository(), permanent: true);
    Get.put(QuestRepository(), permanent: true);

    // 2. 业务服务 (Domain/Service Layer)
    // 顺序很重要：QuestService 依赖 Repo，TimeService 依赖 QuestService
    Get.put(QuestService(), permanent: true);
    Get.put(TimeService(), permanent: true);
  }
}
