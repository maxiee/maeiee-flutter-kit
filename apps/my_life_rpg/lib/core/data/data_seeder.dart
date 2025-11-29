import 'package:get/get.dart';
import 'package:my_life_rpg/models/quest.dart';
import 'package:my_life_rpg/services/quest_service.dart';

/// [DataSeeder]
/// 负责在应用启动时填充初始数据 (Mock Data)。
/// 在开发阶段用于快速验证功能，生产环境应禁用。
class DataSeeder {
  static void run() {
    // 确保 Service 已注入
    if (!Get.isRegistered<QuestService>()) return;

    final QuestService qs = Get.find();

    // [修改点]：如果已经有数据（比如从硬盘加载了），就不要再播种了
    // 这样保证用户的数据不会被 Mock 数据覆盖或重复添加
    if (qs.projects.isNotEmpty || qs.quests.isNotEmpty) {
      print("💾 Data loaded from storage. Seeder skipped.");
      return;
    }

    print("🌱 Storage empty. Seeding Mock Data...");

    // 1. 添加项目
    qs.addProject("Flutter架构演进", "技术专家之路", 100, 0); // Orange
    qs.addProject("独立开发: NEXUS", "副业破局点", 50, 1); // Cyan
    qs.addProject("身体重构计划", "健康是革命的本钱", 30, 3); // Green

    // 获取刚才创建的项目引用
    final pFlutter = qs.projects.firstWhere((p) => p.title.contains("Flutter"));
    final pIndie = qs.projects.firstWhere((p) => p.title.contains("NEXUS"));

    // 2. 添加 Mission (关联项目)
    qs.addNewQuest(
      title: "阅读 RenderObject 源码",
      type: QuestType.mission,
      project: pFlutter,
      deadline: DateTime.now().add(const Duration(hours: 4)), // 今天稍晚
    );

    qs.addNewQuest(
      title: "编写 MVP 架构文档",
      type: QuestType.mission,
      project: pIndie,
      deadline: DateTime.now().add(const Duration(days: 2)), // 后天
    );

    // 3. 添加 Standalone Mission (无项目)
    qs.addNewQuest(
      title: "购买猫粮",
      type: QuestType.mission,
      deadline: DateTime.now().subtract(const Duration(hours: 1)), // 已逾期 (测试用)
    );

    // 4. 添加 Daemon (循环任务)
    qs.addNewQuest(
      title: "清理厨房水槽",
      type: QuestType.daemon,
      interval: 1, // 每日
    );

    qs.addNewQuest(
      title: "每周周报复盘",
      type: QuestType.daemon,
      interval: 7, // 每周
    );
  }
}
