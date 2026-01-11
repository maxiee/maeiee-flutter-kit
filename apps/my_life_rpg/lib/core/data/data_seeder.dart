import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/models/task.dart';
import 'package:my_life_rpg/services/task_service.dart';

/// [DataSeeder]
/// 负责在应用启动时填充初始数据 (Mock Data)。
/// 在开发阶段用于快速验证功能，生产环境应禁用。
class DataSeeder {
  static void run() {
    // 确保 Service 已注入
    if (!Get.isRegistered<TaskService>()) return;

    final TaskService qs = Get.find();

    // 仅当 "Directions" 为空时，强制注入默认方向
    // 即使 Task 不为空，只要 Direction 为空，我们就补全它，方便老用户迁移
    if (qs.directions.isEmpty) {
      debugPrint("⚠️ No Directions detected. Injecting Cyberpunk Protocols...");
      _injectDirections(qs);
    } else {
      debugPrint("✅ Directions verified. Seeding skipped.");
    }

    // [修改点]：如果已经有数据（比如从硬盘加载了），就不要再播种了
    // 这样保证用户的数据不会被 Mock 数据覆盖或重复添加
    if (qs.projects.isNotEmpty || qs.tasks.isNotEmpty) {
      debugPrint("💾 Data loaded from storage. Seeder skipped.");
      return;
    }

    debugPrint("🌱 Storage empty. Initializing Cyberpunk Protocol...");

    // [Trick] 获取刚才创建的 Direction 对象引用 (通过标题查找)
    // 因为 addDirection 返回 void，我们需要重新从列表中捞出来
    final dirWork = qs.directions.firstWhere((d) => d.title == "工作");
    final dirSide = qs.directions.firstWhere((d) => d.title == "副业");
    final dirHealth = qs.directions.firstWhere((d) => d.title == "健康");

    // ==========================================
    // 2. Create Projects (战术层) - 关联到 Direction
    // ==========================================

    qs.addProject(
      "Flutter架构演进",
      "技术专家之路",
      100,
      0, // Cyan
      directionId: dirWork.id, // [New] 挂载到 工作
    );

    qs.addProject(
      "独立开发: NEXUS",
      "副业破局点",
      50,
      1, // Magenta
      directionId: dirSide.id, // [New] 挂载到 副业
    );

    qs.addProject(
      "身体重构计划",
      "健康是革命的本钱",
      30,
      3, // Green
      directionId: dirHealth.id, // [New] 挂载到 健康
    );

    // 获取 Project 引用
    final pFlutter = qs.projects.firstWhere((p) => p.title.contains("Flutter"));
    final pIndie = qs.projects.firstWhere((p) => p.title.contains("NEXUS"));

    // ==========================================
    // 3. Create Missions (执行层) - 保持不变
    // ==========================================

    qs.addNewTask(
      title: "阅读 RenderObject 源码",
      type: TaskType.todo,
      project: pFlutter,
      deadline: DateTime.now().add(const Duration(hours: 4)),
    );

    qs.addNewTask(
      title: "编写 MVP 架构文档",
      type: TaskType.todo,
      project: pIndie,
      deadline: DateTime.now().add(const Duration(days: 2)),
    );

    // Standalone Mission (无项目，自然也无方向，属于 Inbox)
    qs.addNewTask(
      title: "购买猫粮",
      type: TaskType.todo,
      deadline: DateTime.now().subtract(const Duration(hours: 1)), // Overdue
    );

    // Daemons (循环任务)
    qs.addNewTask(title: "清理厨房水槽", type: TaskType.routine, interval: 1);

    qs.addNewTask(title: "每周周报复盘", type: TaskType.routine, interval: 7);
  }

  static void _injectDirections(TaskService qs) {
    // 1. Create Directions
    qs.addDirection("工作", "Mainframe Operations", 0, Icons.work);
    qs.addDirection("副业", "New DLC Development", 1, Icons.business_center);
    qs.addDirection("健康", "Bio-Mechanical Maintenance", 3, Icons.favorite);
    qs.addDirection("生活", "Background Processes", 2, Icons.home);
    qs.addDirection("学习", "Knowledge Acquisition", 4, Icons.school);

    debugPrint("✨ Directions Injected. Please Restart App or Hot Reload.");
  }
}
