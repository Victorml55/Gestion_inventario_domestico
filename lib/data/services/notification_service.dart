import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(initSettings);
  }

  static Future<void> programarAlarma(int id, String producto, DateTime fecha) async {
    final tzFecha = tz.TZDateTime.from(fecha, tz.local).add(const Duration(hours: 8)); // 8:00 AM
    
    // Si la fecha ya pasó, no programar
    if (tzFecha.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      'Producto por caducar',
      'El producto "$producto" caduca hoy.',
      tzFecha,
      const NotificationDetails(
        android: AndroidNotificationDetails('caducidad_channel', 'Caducidad',
            importance: Importance.max, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'caducidad',
    );
  }

  static Future<void> cancelarTodas() async {
    await _plugin.cancelAll();
  }
}