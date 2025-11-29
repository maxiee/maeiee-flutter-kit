// lib/core/theme/app_text_styles.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const _fontFamily = 'Courier'; // 核心特征

  // H1: 巨型数字 (Session Timer)
  static const heroNumber = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 56,
    fontWeight: FontWeight.bold,
    letterSpacing: 6,
    color: AppColors.accentMain,
  );

  // H2: 面板标题
  static const panelHeader = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textSecondary,
    letterSpacing: 1.0,
  );

  // Body: 列表内容
  static const body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    color: AppColors.textPrimary,
  );

  // Caption: 极小标签 (Tag / Matrix Label)
  static const caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    color: AppColors.textDim,
  );

  // Micro: 矩阵内的 7px 文字
  static const micro = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 7,
    fontWeight: FontWeight.bold,
    height: 1.0,
  );
}
