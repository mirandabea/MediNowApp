import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/medicamento_model.dart';
import 'prefs_service.dart';

class NotificationService {
  static FlutterLocalNotificationsPlugin? _plugin;
  static void Function(NotificationResponse)? _onTap;

  static const _channelId = 'medinow_canal';
  static const _channelName = 'Lembretes de Medicamentos';
  static const _channelDesc = 'Notificações de horário de medicamentos';

  static Future<void> init({
    required void Function(NotificationResponse) onForegroundTap,
    required void Function(NotificationResponse) onBackgroundTap,
  }) async {
    _onTap = onForegroundTap;
    _plugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin!.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _handleTap,
      onDidReceiveBackgroundNotificationResponse: onBackgroundTap,
    );

    final androidImpl = _plugin!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.requestNotificationsPermission();

    final canSchedule = await androidImpl?.canScheduleExactNotifications();
    if (canSchedule == false) {
      await androidImpl?.requestExactAlarmsPermission();
    }
  }

  static Future<NotificationAppLaunchDetails?> obterDetalhesLancamento() async {
    return _plugin?.getNotificationAppLaunchDetails();
  }

  static void _handleTap(NotificationResponse response) {
    if (_onTap != null && response.payload != null) {
      _onTap!(response);
    }
  }

  static List<DateTime> calcularJanela(
    MedicamentoModel med,
    DateTime aPartirDe, {
    int janelaHoras = 48,
    int maxQtd = 15,
  }) {
    final limite = aPartirDe.add(Duration(hours: janelaHoras));
    final fimEfetivo =
        med.dataFim ?? aPartirDe.add(const Duration(days: 365));

    var t = med.dataInicio;
    if (t.isBefore(aPartirDe)) {
      final diffMin = aPartirDe.difference(t).inMinutes;
      final freqMin = med.frequenciaHoras * 60;
      final intervals = (diffMin / freqMin).ceil();
      t = t.add(Duration(minutes: freqMin * intervals));
    }

    final result = <DateTime>[];
    while (!t.isAfter(limite) &&
        !t.isAfter(fimEfetivo) &&
        result.length < maxQtd) {
      result.add(t);
      t = t.add(Duration(hours: med.frequenciaHoras));
    }
    return result;
  }

  static Future<List<String>> agendarJanela(MedicamentoModel med) async {
    final horarios = calcularJanela(med, DateTime.now());
    final agendadas = <String>[];

    for (final horario in horarios) {
      final isoString = horario.toIso8601String();
      final notifId = _gerarId(med.id, isoString);
      final payload = jsonEncode({
        'medicamentoId': med.id,
        'userId': med.userId,
        'nome': med.nome,
        'dosagem': med.dosagem,
        'colorValue': med.colorValue,
        'horarioAgendado': isoString,
      });

      try {
        await _plugin!.zonedSchedule(
          notifId,
          'Hora do medicamento! 💊',
          '${med.nome} - ${med.dosagem}',
          tz.TZDateTime.from(horario, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDesc,
              importance: Importance.max,
              priority: Priority.high,
              color: Color(med.colorValue),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        agendadas.add(isoString);
      } catch (_) {}
    }

    return agendadas;
  }

  static Future<String?> agendarProxima(
    MedicamentoModel med,
    DateTime aposHorario,
  ) async {
    final horarios = calcularJanela(
      med,
      aposHorario,
      janelaHoras: 24 * 30,
      maxQtd: 1,
    );

    if (horarios.isEmpty) return null;

    final horario = horarios.first;
    final isoString = horario.toIso8601String();
    final notifId = _gerarId(med.id, isoString);
    final payload = jsonEncode({
      'medicamentoId': med.id,
      'userId': med.userId,
      'nome': med.nome,
      'dosagem': med.dosagem,
      'colorValue': med.colorValue,
      'horarioAgendado': isoString,
    });

    try {
      await _plugin!.zonedSchedule(
        notifId,
        'Hora do medicamento! 💊',
        '${med.nome} - ${med.dosagem}',
        tz.TZDateTime.from(horario, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.high,
            color: Color(med.colorValue),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      return isoString;
    } catch (_) {
      return null;
    }
  }

  static Future<void> cancelarMedicamento(String medicamentoId) async {
    final todos = await PrefsService.instance.listarTodosMedicamentos();
    try {
      final med = todos.firstWhere((m) => m.id == medicamentoId);
      for (final iso in med.horariosAgendados) {
        await _plugin?.cancel(_gerarId(medicamentoId, iso));
      }
    } catch (_) {}
  }

  static int _gerarId(String medicamentoId, String horario) {
    final input = '$medicamentoId|$horario';
    final bytes = utf8.encode(input);
    final hashBytes = sha256.convert(bytes).bytes;
    return ((hashBytes[0] << 24) |
            (hashBytes[1] << 16) |
            (hashBytes[2] << 8) |
            hashBytes[3])
        .abs();
  }
}
