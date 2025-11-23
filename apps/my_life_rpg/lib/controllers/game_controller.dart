import 'package:get/get.dart';
import '../models/quest.dart';

class GameController extends GetxController {
  // 玩家状态 Mock
  final hp = '中'.obs; // HIGH, NORMAL, LOW
  final mpCurrent = 4.5.obs; // 剩余 4.5 小时
  final mpTotal = 6.0;

  // 任务列表 Mock
  final quests = <Quest>[].obs;

  @override
  void onInit() {
    super.onInit();
    // 制造假数据
    quests.addAll([
      Quest(
        id: '1',
        title: '技能: Flutter 架构',
        type: QuestType.project,
        totalDurationSeconds: 36000,
      ), // 10小时
      Quest(
        id: '2',
        title: '业余项目: 个人管理系统',
        type: QuestType.project,
        totalDurationSeconds: 7200,
      ), // 2小时
      Quest(
        id: '3',
        title: '写作: The Maeiee Book',
        type: QuestType.project,
        totalDurationSeconds: 18000,
      ), // 5小时

      Quest(
        id: '4',
        title: '维护: 管道维护',
        type: QuestType.routine,
        intervalDays: 21,
        lastDoneAt: DateTime.now().subtract(Duration(days: 25)),
      ), // 逾期
      Quest(
        id: '5',
        title: '备份: 摄像头视频',
        type: QuestType.routine,
        intervalDays: 30,
        lastDoneAt: DateTime.now().subtract(Duration(days: 10)),
      ), // 正常
    ]);
  }
}
