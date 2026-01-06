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

    // 1. 幂等性检查：如果已有任何数据，跳过播种
    if (qs.directions.isNotEmpty ||
        qs.projects.isNotEmpty ||
        qs.tasks.isNotEmpty) {
      print("💾 Data loaded from storage. Seeder skipped.");
      return;
    }

    print("🌱 Storage empty. Initializing Cyberpunk Protocol...");

    // ==========================================
    // 1. Create Directions (战略层)
    // ==========================================

    // 主业 (Cyan)
    qs.addDirection("SYSTEM CORE", "Mainframe Operations", 0, Icons.memory);

    // 副业 (Magenta)
    qs.addDirection("EXPANSION", "New DLC Development", 1, Icons.extension);

    // 身体 (Green)
    qs.addDirection(
      "HARDWARE",
      "Bio-Mechanical Maintenance",
      3,
      Icons.monitor_heart,
    );

    // 生活 (Orange)
    qs.addDirection("RUNTIME", "Background Processes", 2, Icons.layers);

    // [Trick] 获取刚才创建的 Direction 对象引用 (通过标题查找)
    // 因为 addDirection 返回 void，我们需要重新从列表中捞出来
    final dirCore = qs.directions.firstWhere((d) => d.title == "SYSTEM CORE");
    final dirExp = qs.directions.firstWhere((d) => d.title == "EXPANSION");
    final dirHard = qs.directions.firstWhere((d) => d.title == "HARDWARE");

    // ==========================================
    // 2. Create Projects (战术层) - 关联到 Direction
    // ==========================================

    qs.addProject(
      "Flutter架构演进",
      "技术专家之路",
      100,
      0, // Cyan
      directionId: dirCore.id, // [New] 挂载到 System Core
    );

    qs.addProject(
      "独立开发: NEXUS",
      "副业破局点",
      50,
      1, // Magenta
      directionId: dirExp.id, // [New] 挂载到 Expansion
    );

    qs.addProject(
      "身体重构计划",
      "健康是革命的本钱",
      30,
      3, // Green
      directionId: dirHard.id, // [New] 挂载到 Hardware
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
}
