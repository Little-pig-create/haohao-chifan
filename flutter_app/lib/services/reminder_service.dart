import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 本地每日提醒。所有时间都是设备本地时间。
class ReminderService {
  ReminderService._();
  static final instance = ReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get _mobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (_ready) return;
    if (!_mobile) {
      _ready = true;
      return;
    }
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // 取不到时区名时保留 timezone 包默认值，提醒时间可能偏移。
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
    );
    _ready = true;
  }

  Future<bool> requestPermission() async {
    if (!_mobile) return false;
    await init();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          true;
    }
    return true;
  }

  Future<void> apply({
    required bool enabled,
    required int waterMinutes,
    required String breakfast,
    required String lunch,
    required String dinner,
    required String weight,
    required String sleep,
  }) async {
    if (!_mobile) return;
    await init();
    await _plugin.cancelAll();
    if (!enabled) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminders',
        '每日提醒',
        channelDescription: '喝水、三餐、称重和睡前提醒',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final fixed = <int, (String, String, String)>{
      1: ('早餐时间', '记下第一餐，给今天一个稳定的开始。', breakfast),
      2: ('午餐时间', '别忘了记录午餐，晚上复盘会更轻松。', lunch),
      3: ('晚餐时间', '晚餐记一笔，今天的热量就完整了。', dinner),
      4: ('称体重吧', '固定时间称重，趋势才有参考意义。', weight),
      5: ('睡前复盘', '花一分钟记下今天，准备休息。', sleep),
    };
    for (final entry in fixed.entries) {
      final time = _parse(entry.value.$3);
      if (time == null) continue;
      await _schedule(
        id: entry.key,
        title: entry.value.$1,
        body: entry.value.$2,
        time: time,
        details: details,
      );
    }

    final step = waterMinutes.clamp(15, 240);
    var id = 100;
    for (var minute = 8 * 60; minute <= 22 * 60; minute += step) {
      await _schedule(
        id: id++,
        title: '该喝水了',
        body: '起身喝一杯水，顺便活动一下。',
        time: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
        details: details,
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required NotificationDetails details,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var date = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!date.isAfter(now)) date = date.add(const Duration(days: 1));
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: date,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  TimeOfDay? _parse(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }
}
