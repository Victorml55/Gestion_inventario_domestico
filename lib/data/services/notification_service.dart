import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../core/date_utils.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _prefijo = 'caducidad:';

  /// Lo asigna la UI (main.dart). Se llama con el día cuando el usuario
  /// toca una notificación con la app abierta o en segundo plano.
  static void Function(DateTime dia)? onAbrirDia;

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (r) => _manejar(r.payload),
    );

    // Android 13+: pedir permiso de notificaciones
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static DateTime? _parse(String? payload) {
    if (payload == null || !payload.startsWith(_prefijo)) return null;
    final d = DateTime.tryParse(payload.substring(_prefijo.length));
    return d == null ? null : normalizarFecha(d);
  }

  static void _manejar(String? payload) {
    final dia = _parse(payload);
    if (dia != null) onAbrirDia?.call(dia);
  }

  /// Si la app se abrió tocando una notificación (estaba cerrada).
  static Future<DateTime?> diaDeLanzamiento() async {
    final d = await _plugin.getNotificationAppLaunchDetails();
    if (d == null || !d.didNotificationLaunchApp) return null;
    return _parse(d.notificationResponse?.payload);
  }

  /// Programa una notificación a las 8:00 del día de caducidad.
  /// El id debe ser el id del lote.
  static Future<void> programarAlarma(
      int id, String producto, DateTime fecha) async {
    //final cuando = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
    final cuando = tz.TZDateTime(tz.local, fecha.year, fecha.month, fecha.day, 8);

    // Si ya pasó, no programar
    if (cuando.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      'Producto por caducar',
      'El producto "$producto" caduca hoy.',
      cuando,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'caducidad_channel',
          'Caducidad',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '$_prefijo${dateToSql(fecha)}',
    );
  }

  static Future<void> cancelar(int id) => _plugin.cancel(id);

  static Future<void> cancelarTodas() => _plugin.cancelAll();
}