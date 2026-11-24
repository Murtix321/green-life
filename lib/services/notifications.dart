import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/plant.dart';

/// Sulama alarmları: her bitkinin bir sonraki sulama gününde, seçilen saatte
/// telefonun kendi bildirim sistemiyle çalar (internet gerekmez, ücretsiz).
class WaterAlarms {
  static final FlutterLocalNotificationsPlugin _p = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _p.initialize(const InitializationSettings(android: android, iOS: ios));
      _ready = true;
    } catch (e) {
      debugPrint('Bildirimler başlatılamadı: $e');
    }
  }

  static Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await _p
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _p
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('Bildirim izni alınamadı: $e');
    }
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'watering',
      'Sulama alarmları',
      channelDescription: 'Bitkilerin sulama günü geldiğinde hatırlatır',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF1F4D36),
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Tüm alarmları baştan kurar. Bitki eklenince, sulanınca veya saat değişince çağrılır.
  static Future<void> rescheduleAll(
    List<Plant> plants, {
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    if (!_ready) return;
    try {
      await _p.cancelAll();
      if (!enabled) return;
      final now = DateTime.now();
      for (var i = 0; i < plants.length; i++) {
        final p = plants[i];
        final n = p.nextWater;
        var when = DateTime(n.year, n.month, n.day, hour, minute);
        while (when.isBefore(now)) {
          when = when.add(const Duration(days: 1));
        }
        await _p.zonedSchedule(
          i,
          'Sulama zamanı: ${p.name}',
          '${p.name} bitkinin toprağını kontrol et ve sula. Sonra uygulamada "Sulandı" de.',
          tz.TZDateTime.from(when, tz.UTC),
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('Alarm kurulamadı: $e');
    }
  }
}
