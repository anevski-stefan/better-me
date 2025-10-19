import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'quotes_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const String _quotesEnabledKey = 'quotes_notifications_enabled';
  static const String _quotesTimeKey = 'quotes_notification_time';
  static const int _quotesNotificationId = 1001;
  static const int _habitNotificationIdBase = 2000; // Base ID for habit notifications

  /// Initialize the notification service
  static Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();
    
    // Android initialization settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings - request alert permission first
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    // Initialize the plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );
    
    // Request permissions
    await _requestPermissions();
  }

  /// Handle notification tap (foreground)
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
    // Could implement navigation to specific screens here
  }

  /// Handle background notification tap
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    // Handle background notification tap
    // This runs in a separate isolate
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    // Request Android permissions
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
    
    // Request iOS permissions
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Check if quotes notifications are enabled
  static Future<bool> areQuotesEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_quotesEnabledKey) ?? false;
  }

  /// Enable or disable quotes notifications
  static Future<void> setQuotesEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quotesEnabledKey, enabled);
    
    if (enabled) {
      await _scheduleDailyQuotes();
    } else {
      await _cancelDailyQuotes();
    }
  }

  /// Get the scheduled time for quotes notifications
  static Future<TimeOfDay?> getQuotesTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('${_quotesTimeKey}_hour');
    final minute = prefs.getInt('${_quotesTimeKey}_minute');
    
    if (hour != null && minute != null) {
      return TimeOfDay(hour: hour, minute: minute);
    }
    return null;
  }

  /// Set the time for quotes notifications
  static Future<void> setQuotesTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_quotesTimeKey}_hour', time.hour);
    await prefs.setInt('${_quotesTimeKey}_minute', time.minute);
    
    // Reschedule if enabled
    if (await areQuotesEnabled()) {
      await _scheduleDailyQuotes();
    }
  }

  /// Schedule daily motivational quotes
  static Future<void> _scheduleDailyQuotes() async {
    // Cancel existing notifications first
    await _cancelDailyQuotes();
    
    final time = await getQuotesTime();
    if (time == null) return;
    
    // Get today's quote
    final quote = QuotesService.getTodaysQuote();
    
    // Android notification details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_quotes',
      'Daily Motivational Quotes',
      channelDescription: 'Receive daily motivational quotes to inspire you',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      showWhen: true,
      enableVibration: true,
      playSound: true,
      autoCancel: true,
      ongoing: false,
    );
    
    // iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
      interruptionLevel: InterruptionLevel.active,
      categoryIdentifier: 'daily_quote',
    );
    
    // Combined notification details
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    final scheduledTime = _nextInstanceOfTime(time.hour, time.minute);
    
    // Schedule the notification using the same approach as the working test
    await _notifications.zonedSchedule(
      _quotesNotificationId,
      'Daily Motivation',
      quote.text,
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'daily_quote',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancel daily quotes notifications
  static Future<void> _cancelDailyQuotes() async {
    await _notifications.cancel(_quotesNotificationId);
  }
  
  /// Schedule habit reminder notifications
  static Future<void> scheduleHabitReminders(String habitId, String habitName, TimeOfDay reminderTime, List<int> reminderDays) async {
    // Cancel existing notifications for this habit first
    await cancelHabitReminders(habitId);
    
    if (reminderDays.isEmpty || reminderTime == null) return;
    
    // Android notification details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'Habit Reminders',
      channelDescription: 'Reminders for your daily habits',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      showWhen: true,
      enableVibration: true,
      playSound: true,
      autoCancel: true,
      ongoing: false,
    );
    
    // iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
      interruptionLevel: InterruptionLevel.active,
      categoryIdentifier: 'habit_reminder',
    );
    
    // Combined notification details
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Schedule notifications for each selected day
    for (int dayOfWeek in reminderDays) {
      final scheduledTime = _getNextInstanceOfDayAndTime(dayOfWeek, reminderTime.hour, reminderTime.minute);
      final notificationId = _habitNotificationIdBase + (habitId.hashCode % 1000) + dayOfWeek;
      
      await _notifications.zonedSchedule(
        notificationId,
        'Habit Reminder',
        'Time for your habit: $habitName',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'habit_reminder_$habitId',
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }
  
  /// Cancel habit reminder notifications
  static Future<void> cancelHabitReminders(String habitId) async {
    // Cancel all possible notification IDs for this habit
    for (int dayOfWeek = 0; dayOfWeek < 7; dayOfWeek++) {
      final notificationId = _habitNotificationIdBase + (habitId.hashCode % 1000) + dayOfWeek;
      await _notifications.cancel(notificationId);
    }
  }
  
  /// Get the next instance of a specific day and time
  static tz.TZDateTime _getNextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    final now = DateTime.now();
    final currentDayOfWeek = now.weekday % 7; // Convert to 0=Sunday format
    
    // Calculate days until the target day
    int daysUntilTarget = (dayOfWeek - currentDayOfWeek) % 7;
    if (daysUntilTarget == 0) {
      // If it's the same day, check if time has passed
      final todayTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (todayTime.isBefore(now)) {
        daysUntilTarget = 7; // Schedule for next week
      }
    }
    
    final targetDate = now.add(Duration(days: daysUntilTarget));
    final scheduledDate = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
    
    return tz.TZDateTime.from(scheduledDate, tz.local);
  }
  

  /// Get the next instance of the specified time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = DateTime.now();
    
    // Create scheduled date for today
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    // Convert to TZDateTime using the same approach as the working test notification
    return tz.TZDateTime.from(scheduledDate, tz.local);
  }


  /// Get notification status
  static Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    
    // For iOS, we can't easily check permissions, so we'll assume they're enabled
    // if the user hasn't explicitly denied them
    return true;
  }
  
  /// Manually request permissions (useful for testing)
  static Future<bool> requestPermissionsManually() async {
    try {
      await _requestPermissions();
      return await areNotificationsEnabled();
    } catch (e) {
      return false;
    }
  }
  
  

  /// Send notification that works in all app states
  static Future<void> sendNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      autoCancel: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }
  
}
