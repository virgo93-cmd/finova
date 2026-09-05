import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static Future<void>? _initialization;

  static Future<void> initialize() => _initialization ??= _initialize();

  static Future<void> _initialize() async {
    try {
      tz_data.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
    } catch (_) {
      // Notifications are optional and must never prevent app startup.
    }
  }

  static Future<bool> setDailyReminder(bool enabled) async {
    await initialize();
    if (!enabled) {
      await _plugin.cancel(id: 1001);
      return true;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidAllowed =
        await android?.requestNotificationsPermission() ?? true;
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosAllowed =
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
    if (!androidAllowed || !iosAllowed) return false;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id: 1001,
      title: 'A moment for your day',
      body: 'Tinjau pengeluaran, tugas, dan kebiasaan hari ini di Finova.',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_review',
          'Daily review',
          channelDescription:
              'A gentle reminder to review money, tasks, and habits.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return true;
  }

  static Future<void> scheduleTask(
    int taskId,
    String title,
    DateTime dueDate,
  ) async {
    await initialize();
    final at = tz.TZDateTime(
      tz.local,
      dueDate.year,
      dueDate.month,
      dueDate.day,
      8,
    );
    if (!at.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id: 100000 + taskId,
      title: 'Tugas hari ini',
      body: title,
      scheduledDate: at,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_due',
          'Pengingat tugas',
          channelDescription:
              'Pengingat tugas Finova pada tanggal jatuh tempo.',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> scheduleDebt(
    int debtId,
    String person,
    DateTime dueDate,
    bool receivable,
  ) async {
    await initialize();
    final at = tz.TZDateTime(
      tz.local,
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9,
    );
    if (!at.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id: 200000 + debtId,
      title: receivable ? 'Piutang jatuh tempo' : 'Hutang jatuh tempo',
      body: receivable
          ? 'Ingat tagihan dari $person.'
          : 'Ingat pembayaran kepada $person.',
      scheduledDate: at,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'debt_due',
          'Jatuh tempo hutang dan piutang',
          channelDescription:
              'Pengingat jatuh tempo catatan hutang dan piutang.',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> scheduleHabit(int habitId, String title) async {
    await initialize();
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: 300000 + habitId,
      title: 'Kebiasaan hari ini',
      body: title,
      scheduledDate: at,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_daily',
          'Pengingat kebiasaan',
          channelDescription: 'Pengingat harian kebiasaan aktif Finova.',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelTask(int id) => _plugin.cancel(id: 100000 + id);
  static Future<void> cancelDebt(int id) => _plugin.cancel(id: 200000 + id);
  static Future<void> cancelHabit(int id) => _plugin.cancel(id: 300000 + id);
  static Future<void> cancelAll() => _plugin.cancelAll();
}
