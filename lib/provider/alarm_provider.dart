import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class AlarmProvider {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> scheduleNotification(
      int id, String title, DateTime dateTime, String repeatType, String sound) async {
    final tz.TZDateTime scheduledDate =
        _getFutureDate(tz.TZDateTime.from(dateTime, tz.local));

    final formattedTime =
        DateFormat.jm().format(dateTime); // Format time as 02:30 AM

    final notificationMessage = 'Alarm is set at $formattedTime';
    print('Scheduling notification with sound: $sound');

    // Define the sound for the notification based on the selected sound
    RawResourceAndroidNotificationSound notificationSound;
    switch (sound) {
      case 'sound1':
        notificationSound = RawResourceAndroidNotificationSound('sound1');
        break;
      case 'sound2':
        notificationSound = RawResourceAndroidNotificationSound('sound2');
        break;
      case 'sound3':
        notificationSound = RawResourceAndroidNotificationSound('sound3');
        break;
      case 'sound4':
        notificationSound = RawResourceAndroidNotificationSound('sound4');
        break;
      case 'sound5':
        notificationSound = RawResourceAndroidNotificationSound('sound5');
        break;
      default:
        notificationSound = RawResourceAndroidNotificationSound('default_sound');
        break;
    }

    // Create or update notification channel
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id_$id', // Unique channel ID for each notification
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      sound: notificationSound,
      playSound: true,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Handle repeat logic based on selected repeatType
    if (repeatType == 'Daily') {
      await _scheduleDailyNotification(
          id, title, notificationMessage, dateTime, platformChannelSpecifics);
    } else if (repeatType == 'Weekday') {
      await _scheduleWeekdayNotifications(
          id, title, notificationMessage, dateTime, platformChannelSpecifics);
    } else if (repeatType == 'Weekend') {
      await _scheduleWeekendNotifications(
          id, title, notificationMessage, dateTime, platformChannelSpecifics);
    } else if (repeatType == 'None') {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        notificationMessage,
        scheduledDate,
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static bool _isValidDayForRepeatType(DateTime dateTime, String repeatType) {
    if (repeatType == 'Weekday') {
      return dateTime.weekday >= DateTime.monday &&
          dateTime.weekday <= DateTime.friday;
    } else if (repeatType == 'Weekend') {
      return dateTime.weekday == DateTime.saturday ||
          dateTime.weekday == DateTime.sunday;
    }
    return true; // For 'None' and 'Daily', any day is valid
  }

  static Future<void> _scheduleDailyNotification(
      int id,
      String title,
      String notificationMessage,
      DateTime dateTime,
      NotificationDetails platformChannelSpecifics) async {
    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.from(dateTime, tz.local);
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      notificationMessage,
      scheduledDate,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'repeat_daily',
    );
  }

  static Future<void> _scheduleWeekdayNotifications(
      int id,
      String title,
      String notificationMessage,
      DateTime dateTime,
      NotificationDetails platformChannelSpecifics) async {
    DateTime startDate = dateTime.isBefore(DateTime.now()) ? DateTime.now() : dateTime;

    for (int i = 0; i < 7; i++) {
      final nextDateTime = startDate.add(Duration(days: i));
      if (nextDateTime.weekday >= DateTime.monday && nextDateTime.weekday <= DateTime.friday) {
        final tz.TZDateTime nextScheduledDate =
            _getFutureDate(tz.TZDateTime.from(nextDateTime, tz.local));
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id + i, // Unique ID for each notification
          title,
          notificationMessage,
          nextScheduledDate,
          platformChannelSpecifics,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'repeat_weekday',
        );
      }
    }
  }

  static Future<void> _scheduleWeekendNotifications(
      int id,
      String title,
      String notificationMessage,
      DateTime dateTime,
      NotificationDetails platformChannelSpecifics) async {
    for (int i = 0; i < 7; i++) {
      final nextDateTime = dateTime.add(Duration(days: i));
      if (nextDateTime.weekday == DateTime.saturday ||
          nextDateTime.weekday == DateTime.sunday) {
        final tz.TZDateTime nextScheduledDate =
            _getFutureDate(tz.TZDateTime.from(nextDateTime, tz.local));
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id + i, // Unique ID for each notification
          title,
          notificationMessage,
          nextScheduledDate,
          platformChannelSpecifics,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'repeat_weekend',
        );
      }
    }
  }

  static Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // Helper function to ensure the date is in the future
  static tz.TZDateTime _getFutureDate(tz.TZDateTime scheduledDate) {
    final now = tz.TZDateTime.now(tz.local);
    if (scheduledDate.isBefore(now)) {
      return scheduledDate.add(Duration(days: 1));
    }
    return scheduledDate;
  }
}
