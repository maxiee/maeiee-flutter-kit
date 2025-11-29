import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

enum LogLevel { info, warning, error, debug }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? tag;

  LogEntry({required this.level, required this.message, this.tag})
    : timestamp = DateTime.now();

  String get timeStr => DateFormat('HH:mm:ss').format(timestamp);
}

class LogService extends GetxService {
  final logs = <LogEntry>[].obs;
  static const int maxLogs = 100;

  // 快捷方法
  static void i(String msg, {String? tag}) => _log(LogLevel.info, msg, tag);
  static void w(String msg, {String? tag}) => _log(LogLevel.warning, msg, tag);
  static void e(String msg, {String? tag}) => _log(LogLevel.error, msg, tag);
  static void d(String msg, {String? tag}) => _log(LogLevel.debug, msg, tag);

  static void _log(LogLevel level, String msg, String? tag) {
    // 1. 控制台打印 (开发环境)
    if (kDebugMode) {
      print('[${level.name.toUpperCase()}] $tag: $msg');
    }

    // 2. 存入内存 (供 UI 显示)
    // 只有已初始化才存，避免极早期崩溃
    if (Get.isRegistered<LogService>()) {
      final service = Get.find<LogService>();
      service.logs.add(LogEntry(level: level, message: msg, tag: tag));

      // 限制长度
      if (service.logs.length > maxLogs) {
        service.logs.removeAt(0);
      }
    }
  }
}
