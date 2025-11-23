import 'package:get/get.dart';
import '../models/quest.dart';

class GameController extends GetxController {
  // 玩家状态 Mock
  final hp = 'NORMAL'.obs; // HIGH, NORMAL, LOW
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
        title: 'Skill: Flutter Arch',
        type: QuestType.project,
        totalDurationSeconds: 36000,
      ), // 10小时
      Quest(
        id: '2',
        title: 'SideProject: NEXUS',
        type: QuestType.project,
        totalDurationSeconds: 7200,
      ), // 2小时
      Quest(
        id: '3',
        title: 'Write: The Maeiee Book',
        type: QuestType.project,
        totalDurationSeconds: 18000,
      ), // 5小时

      Quest(
        id: '4',
        title: 'Maintain: Kitchen Sink',
        type: QuestType.routine,
        intervalDays: 21,
        lastDoneAt: DateTime.now().subtract(Duration(days: 25)),
      ), // 逾期
      Quest(
        id: '5',
        title: 'Backup: CCTV Footage',
        type: QuestType.routine,
        intervalDays: 30,
        lastDoneAt: DateTime.now().subtract(Duration(days: 10)),
      ), // 正常
    ]);
  }
}
