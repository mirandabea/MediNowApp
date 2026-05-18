import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'app.dart';
import 'data/local/notification_service.dart';
import 'data/local/prefs_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (response.payload != null) {
    await PrefsService.instance.salvarNotificacaoPendente(response.payload!);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

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

  final launchDetails = await NotificationService.obterDetalhesLancamento();
  if (launchDetails?.didNotificationLaunchApp == true) {
    final payload = launchDetails?.notificationResponse?.payload;
    if (payload != null) {
      await PrefsService.instance.salvarNotificacaoPendente(payload);
    }
  }

  runApp(const MediNowApp());
}
