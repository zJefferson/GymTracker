import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(
            android: androidSettings, iOS: iosSettings),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      _initialized = true;
    } catch (_) {
      // Notificações são um extra; se a inicialização falhar (ex: permissão
      // negada), o app continua funcionando normalmente com som/vibração.
    }
  }

  Future<void> showRestFinished() async {
    if (!_initialized) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'rest_timer',
          'Cronômetro de descanso',
          channelDescription: 'Alerta de fim do descanso entre séries',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.show(
        id: 0,
        title: 'Descanso finalizado',
        body: 'Hora de continuar o treino!',
        notificationDetails: details,
      );
    } catch (_) {
      // Ignora falha de notificação silenciosamente.
    }
  }
}
