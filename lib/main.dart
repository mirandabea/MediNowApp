import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'app.dart';
import 'data/local/notification_service.dart';
import 'data/local/prefs_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  if (response.payload != null) {
    await PrefsService.instance.salvarNotificacaoPendente(response.payload!);
  }
}

Future<void> main() async {
  final t0 = DateTime.now();
  debugPrint('[INIT] main() started at ${t0.toIso8601String()}');

  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[INIT] ensureInitialized: ${DateTime.now().difference(t0).inMilliseconds}ms');

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
  debugPrint('[INIT] timezones: ${DateTime.now().difference(t0).inMilliseconds}ms');

  await NotificationService.init(
    onForegroundTap: (response) {
      if (response.payload != null) {
        navigatorKey.currentState?.pushNamed(
          '/notification-action',
          arguments: response.payload,
        );
      }
    },
    onBackgroundTap: notificationTapBackground,
  );
  debugPrint('[INIT] NotificationService.init: ${DateTime.now().difference(t0).inMilliseconds}ms');

  runApp(const MediNowApp());
  debugPrint('[INIT] runApp: ${DateTime.now().difference(t0).inMilliseconds}ms');
}
