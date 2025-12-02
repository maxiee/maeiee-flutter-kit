class Constants {
  // Time System
  static const int blocksPerDay = 96;
  static const int minutesPerBlock = 15;
  static const int dayStartHour = 8;
  static const int dayEndHour = 25; // 01:00 AM next day

  // XP System
  static const int xpPerMinute = 1;
  static const int xpBonusCompletion = 50;
  static const int levelBaseConstant = 50;

  // Storage Keys
  static const String keyQuests = 'db_quests';
  static const String keyProjects = 'db_projects';

  // Limits
  static const int maxLogsInMemory = 100;
}
