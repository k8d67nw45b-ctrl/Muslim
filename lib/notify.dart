import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tzd;
import 'package:timezone/timezone.dart' as tz;

class AppNotify {
  static final _p = FlutterLocalNotificationsPlugin();
  static const _names = {
    'Fajr': 'الفجر',
    'Dhuhr': 'الظهر',
    'Asr': 'العصر',
    'Maghrib': 'المغرب',
    'Isha': 'العشاء'
  };

  static Future<void> init() async {
    try {
      tzd.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
      await _p.initialize(const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings()));
      final a = _p.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await a?.requestNotificationsPermission();
      await a?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  static Future<void> scheduleDhikrPeriodic() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'dhikr_channel',
        'أذكار تذكيرية',
        channelDescription: 'إشعارات دورية للتذكير بالأذكار والصلاة على النبي',
        importance: Importance.high,
        priority: Priority.high,
      );
      const notificationDetails = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

      await _p.periodicallyShow(
        999,
        'رفيق المسلم | تذكير بالأذكار',
        'اللهم صل وسلم وبارك على نبينا محمد وعلى آله وصحبه أجمعين 🌸',
        RepeatInterval.hourly,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {}
  }

  static Future<void> schedule(double lat, double lng) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      for (var d = 0; d < 3; d++) {
        final day = now.add(Duration(days: d));
        final r = await http.get(Uri.parse(
            'https://api.aladhan.com/v1/timings/${day.day}-${day.month}-${day.year}?latitude=$lat&longitude=$lng&method=4'));
        final t = jsonDecode(r.body)['data']['timings'];
        var i = 0;
        for (final e in _names.entries) {
          final hm = (t[e.key] as String).split(' ')[0].split(':');
          final when = tz.TZDateTime(tz.local, day.year, day.month, day.day,
              int.parse(hm[0]), int.parse(hm[1]));
          if (when.isAfter(now)) {
            await _p.zonedSchedule(
              d * 10 + i,
              'حان وقت صلاة ${e.value}',
              'حيّ على الصلاة، حيّ على الفلاح',
              when,
              const NotificationDetails(
                  android: AndroidNotificationDetails('adhan', 'مواقيت الصلاة',
                      importance: Importance.max, priority: Priority.high),
                  iOS: DarwinNotificationDetails()),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
            );
          }
          i++;
        }
      }
    } catch (_) {}
  }
}
