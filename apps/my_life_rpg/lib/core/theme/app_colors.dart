// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // --- Base Backgrounds ---
  static const bgDarkest = Color(0xFF0F0F0F); // 驾驶舱背景 (Deep Void)
  static const bgDarker = Color(0xFF121212); // 首页背景 (Void)
  static const bgPanel = Color(0xFF1A1A1A); // 面板背景 (Carbon)
  static const bgCard = Color(0xFF252525); // 卡片背景 (Steel)
  static const bgInput = Colors.black38; // 输入框背景

  // --- Semantic Accents ---
  static const accentMain = Colors.orangeAccent; // 主线/创造 (Amber Energy)
  static const accentSystem = Colors.cyanAccent; // 系统/维护 (Neon Flux)
  static const accentDanger = Colors.redAccent; // 警告/Deadline (Critical)
  static const accentSafe = Colors.greenAccent; // 安全/休息 (Stable)

  // --- Text & Icons ---
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white70;
  static const textDim = Colors.white30; // 极淡，用于编号/水印

  // --- Borders ---
  static const borderDim = Colors.white10;
  static const borderBright = Colors.white24;
}
