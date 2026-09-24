import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Plant lokale Erinnerungen für Prüftermine, Vignetten- und
/// Versicherungsfälligkeiten. Zeitzone ist auf Europe/Vienna fest codiert,
/// da die App für den österreichischen Markt gebaut ist.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'fuhrparkmeister_termine';
  static const _channelName = 'Fuhrpark-Termine';
  static const _channelDescription =
      'Erinnerungen an Prüftermine, Vignetten und Versicherungen';

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Vienna'));

    const androidInit = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(initSettings);

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  int _notificationId(String sourceId) => sourceId.hashCode & 0x7fffffff;

  Future<void> scheduleReminder({
    required String sourceId,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await init();
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      _notificationId(sourceId),
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // inexact genügt für tagesgenaue Erinnerungen und braucht keine
      // gesonderte "Alarme & Erinnerungen"-Berechtigung (Android 12+).
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(String sourceId) async {
    await init();
    await _plugin.cancel(_notificationId(sourceId));
  }
}
