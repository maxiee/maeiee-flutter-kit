// lib/core/theme/app_spacing.dart
import 'package:flutter/material.dart';

/// 统一间距系统
/// 基于 4px 网格系统，确保整个应用的间距一致
class AppSpacing {
  // === 基础间距 ===
  static const double xs = 4.0; // 极小
  static const double sm = 8.0; // 小
  static const double md = 12.0; // 中
  static const double lg = 16.0; // 大
  static const double xl = 20.0; // 特大
  static const double xxl = 24.0; // 超大
  static const double xxxl = 32.0; // 巨大

  // === 圆角 ===
  static const double radiusSm = 2.0; // 锐利 (Tag, Chip)
  static const double radiusMd = 4.0; // 标准 (Button, Input)
  static const double radiusLg = 8.0; // 面板 (Card, Panel)
  static const double radiusXl = 12.0; // 大容器 (HUD)

  // === 边框宽度 ===
  static const double borderThin = 1.0;
  static const double borderMedium = 2.0;

  // === 图标尺寸 ===
  static const double iconXs = 8.0;
  static const double iconSm = 14.0;
  static const double iconMd = 18.0;
  static const double iconLg = 20.0;
  static const double iconXl = 24.0;

  // === 常用 EdgeInsets ===
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);

  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(
    horizontal: sm,
  );
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(
    horizontal: md,
  );
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(
    horizontal: lg,
  );

  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(
    vertical: sm,
  );
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(
    vertical: md,
  );
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(
    vertical: lg,
  );

  // === 常用 SizedBox Gaps ===
  static const SizedBox gapH4 = SizedBox(width: xs);
  static const SizedBox gapH8 = SizedBox(width: sm);
  static const SizedBox gapH12 = SizedBox(width: md);
  static const SizedBox gapH16 = SizedBox(width: lg);

  static const SizedBox gapV4 = SizedBox(height: xs);
  static const SizedBox gapV8 = SizedBox(height: sm);
  static const SizedBox gapV12 = SizedBox(height: md);
  static const SizedBox gapV16 = SizedBox(height: lg);
  static const SizedBox gapV20 = SizedBox(height: xl);
  static const SizedBox gapV24 = SizedBox(height: xxl);

  // === 常用 BorderRadius ===
  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);

  // === 容器高度常量 ===
  static const double buttonHeight = 36.0;
  static const double inputHeight = 44.0;
  static const double chipHeight = 28.0;
  static const double hourRowHeight = 24.0;
  static const double campaignBarHeight = 60.0;
}
