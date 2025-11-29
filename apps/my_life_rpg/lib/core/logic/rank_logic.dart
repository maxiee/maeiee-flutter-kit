// lib/core/logic/rank_logic.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum SessionRank { S, A, B, C, D }

class RankResult {
  final SessionRank rank;
  final String label;
  final Color color;
  final String comment;

  RankResult(this.rank, this.label, this.color, this.comment);
}

class RankLogic {
  static RankResult calculate(int seconds) {
    final minutes = seconds / 60;

    if (minutes >= 120) {
      // 2小时以上
      return RankResult(SessionRank.S, "S", Colors.amber, "LEGENDARY FOCUS");
    } else if (minutes >= 90) {
      // 1.5小时
      return RankResult(SessionRank.A, "A", AppColors.accentMain, "DEEP DIVE");
    } else if (minutes >= 45) {
      // 45分钟
      return RankResult(SessionRank.B, "B", AppColors.accentSafe, "SOLID WORK");
    } else if (minutes >= 15) {
      // 15分钟
      return RankResult(SessionRank.C, "C", AppColors.accentSystem, "ROUTINE");
    } else {
      return RankResult(SessionRank.D, "D", Colors.grey, "CASUAL");
    }
  }
}
