import 'package:get/get.dart';
import 'package:my_life_rpg/core/data/project_repository.dart';
import 'package:my_life_rpg/core/data/quest_repository.dart';
import 'package:my_life_rpg/models/quest.dart';
import 'package:my_life_rpg/services/quest_service.dart';
import 'package:my_life_rpg/services/time_service.dart';

class GameController extends GetxController {
  @override
  void onInit() {
    super.onInit();

    // 1. 初始化底层仓储
    Get.put(ProjectRepository());
    Get.put(QuestRepository());

    // 2. 初始化业务服务
    final questService = Get.put(QuestService());
    Get.put(TimeService());

    // 3. 加载 Mock 数据 (现在在这里做，而不是 Service 内部)
    _loadMockData(questService);
  }

  void _loadMockData(QuestService qs) {
    // 调用 qs.addProject, qs.addNewQuest 等方法填充数据
    // ... 把原来 Service 里的 loadMockData 逻辑搬到这里 ...
    qs.addProject("Flutter架构演进", "技术专家之路", 100, 0);
    qs.addProject("独立开发: NEXUS", "副业破局点", 50, 1);

    final p1 = qs.projects.firstWhere((p) => p.title.contains("Flutter"));

    qs.addNewQuest(
      title: "阅读 RenderObject 源码",
      type: QuestType.mission,
      project: p1,
    );
    qs.addNewQuest(title: "清理厨房水槽", type: QuestType.daemon, interval: 1);
  }
}
