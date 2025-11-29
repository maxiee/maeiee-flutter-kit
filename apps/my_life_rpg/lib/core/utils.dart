import 'package:intl/intl.dart';

class Utils {
  // 秒 -> HH:MM:SS
  static String formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // DateTime -> MM-dd HH:mm
  static String formatTime(DateTime dt) {
    return DateFormat('MM-dd HH:mm').format(dt);
  }

  // DateTime -> yyyy-MM-dd
  static String formatDate(DateTime dt) {
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  // 补零
  static String pad0(int n) => n.toString().padLeft(2, '0');
}
