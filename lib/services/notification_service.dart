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

  /// Initialize the notification service
  static Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();
    
    // Android initialization settings with foreground service
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
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
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
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
    );
    
    // Combined notification details
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Schedule the notification
    await _notifications.zonedSchedule(
      _quotesNotificationId,
      'Daily Motivation',
      quote.text,
      _nextInstanceOfTime(time.hour, time.minute),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'daily_quote',
    );
  }

  /// Cancel daily quotes notifications
  static Future<void> _cancelDailyQuotes() async {
    await _notifications.cancel(_quotesNotificationId);
  }

  /// Get the next instance of the specified time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  /// Send a test notification immediately
  static Future<void> sendTestNotification() async {
    final quote = QuotesService.getRandomQuote();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_quotes',
      'Test Motivational Quote',
      channelDescription: 'Test notification for motivational quotes',
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
      9999, // Test notification ID
      'Test Motivation',
      quote.text,
      notificationDetails,
      payload: 'test_quote',
    );
  }

  /// Get notification status
  static Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    return true; // Assume enabled on iOS if we can't check
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
