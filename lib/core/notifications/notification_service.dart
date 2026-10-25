import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// One notification to post at [at].
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
  });

  final int id;
  final String title;
  final String body;
  final DateTime at;
}

/// Thin wrapper around `flutter_local_notifications`, overridable in tests.
///
/// Two gotchas from earlier apps, both handled: the plugin does NOT register
/// its scheduled/boot receivers through manifest merging (they're declared in
/// AndroidManifest.xml), and `inexactAllowWhileIdle` alarms can silently
/// never fire once Android freezes the app, so everything is scheduled exact,
/// which needs the one-time "Alarms & reminders" grant.
class NotificationService {
  static const _channelId = 'servobuddy_reminders';
  static const _channelName = 'Car reminders';
  static const _channelDescription = 'Service due, rego and insurance renewals';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Exception {
      // Stays on UTC: reminders would come at the wrong hour, but still come.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      ),
    );
    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );
    _initialized = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> requestPermissions() async {
    await _android?.requestNotificationsPermission();
    if (!await canScheduleExact()) {
      await _android?.requestExactAlarmsPermission();
    }
  }

  Future<bool> notificationsEnabled() async =>
      await _android?.areNotificationsEnabled() ?? false;

  Future<bool> canScheduleExact() async =>
      await _android?.canScheduleExactNotifications() ?? false;

  Future<void> requestExactAlarmPermission() async =>
      _android?.requestExactAlarmsPermission();

  Future<void> requestNotificationPermission() async =>
      _android?.requestNotificationsPermission();

  /// Cancels everything scheduled and schedules [plan] instead. The plan is
  /// small (a few per car), so a full replace is simpler than diffing.
  Future<void> replaceAll(List<PlannedNotification> plan) async {
    await init();
    await _plugin.cancelAll();
    final exact = await canScheduleExact();
    final now = tz.TZDateTime.now(tz.local);
    for (final n in plan) {
      final at = tz.TZDateTime.from(n.at, tz.local);
      if (!at.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: n.id,
        scheduledDate: at,
        title: n.title,
        body: n.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        // Without the grant, inexact is the only option left; better than none.
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
