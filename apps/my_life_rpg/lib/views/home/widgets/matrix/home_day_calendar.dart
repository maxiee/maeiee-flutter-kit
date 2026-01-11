import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_life_rpg/controllers/matrix_controller.dart';
import 'package:rpg_cyber_ui/rpg_cyber_ui.dart';

class HomeDayCalendar extends StatelessWidget {
  final MatrixController c = Get.find();

  HomeDayCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return DayView<SessionData>(
      key: c.dayViewKey,
      controller: c.eventController,

      // [关键修复 1] 隐藏默认的粉色 Header，因为上方已经有 DateControllerBar 了
      dayTitleBuilder: DayHeader.hidden,

      // [关键修复 2] 背景透明，透出底层的深色
      backgroundColor: Colors.transparent,

      // 基础布局
      heightPerMinute: 1.5, // 稍微拉高一点，增加呼吸感
      startHour: 0,
      endHour: 24,
      showVerticalLine: false,
      timeLineOffset: 4,
      timeLineWidth: 50, // 确保左侧时间轴有足够宽度
      // 交互
      onEventTap: (events, date) => c.onEventTapped(events.first),
      onDateLongPress: (date) => c.onSlotLongPressed(date),

      // --- 视觉风格定制 (Cyberpunk Styling) ---

      // A. 时间轴 (Timeline): 灰色等宽字体
      timeLineBuilder: (date) {
        return Transform.translate(
          offset: const Offset(0, -6),
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              "${date.hour.toString().padLeft(2, '0')}:00",
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.textDim.withOpacity(0.5),
                fontFamily: 'Courier',
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },

      // B. 小时线 (Grid Lines): 极细的虚线，模拟全息投影
      hourIndicatorSettings: HourIndicatorSettings(
        color: Colors.white.withOpacity(0.05), // 非常淡的白线
        height: 1,
        dashWidth: 2,
        dashSpaceWidth: 4,
        lineStyle: LineStyle.dashed,
      ),

      // [关键修复 3] 当前时间指针: 移除圆角气泡，改为硬核红线
      liveTimeIndicatorSettings: const LiveTimeIndicatorSettings(
        color: AppColors.accentDanger, // 激光红
        height: 1,
        showBullet: false, // 不显示左侧圆点，太圆润了
        showTime: true, // 显示时间文字
        showTimeBackgroundView: false, // [重点] 关掉那个圆角背景气泡
        offset: 20,
      ),

      // D. 事件块渲染 (Event Tile): 保持之前的霓虹风格
      eventTileBuilder: (date, events, boundary, start, end) {
        final event = events.first;
        final color = event.color;

        return Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), // 低透明度填充
            border: Border(
              left: BorderSide(color: color, width: 2), // 左侧强调线
              top: BorderSide(color: color.withOpacity(0.3), width: 1),
              bottom: BorderSide(color: color.withOpacity(0.3), width: 1),
              right: BorderSide(color: color.withOpacity(0.3), width: 1),
            ),
            // 不使用圆角，保持硬朗
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Courier',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (event.description?.isNotEmpty ?? false)
                Text(
                  event.description!,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontFamily: 'Courier',
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        );
      },
    );
  }
}
