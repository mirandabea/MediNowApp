import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/colors.dart';
import '../../data/local/notification_service.dart';
import '../../data/local/prefs_service.dart';
import '../../data/models/historico_model.dart';
import '../../domain/repositories/medicamento_repository.dart';

class NotificationActionScreen extends StatefulWidget {
  const NotificationActionScreen({super.key});

  @override
  State<NotificationActionScreen> createState() =>
      _NotificationActionScreenState();
}

class _NotificationActionScreenState extends State<NotificationActionScreen> {
  bool _isProcessing = false;

  void _agendarProxima(String medicamentoId, DateTime horarioAgendado) {
    Future(() async {
      try {
        final todos =
            await PrefsService.instance.listarTodosMedicamentos();
        final med = todos.firstWhere((m) => m.id == medicamentoId);
        final novaIso =
            await NotificationService.agendarProxima(med, horarioAgendado);
        if (novaIso != null) {
          final atualizado = med.copyWith(
            horariosAgendados: [...med.horariosAgendados, novaIso],
          );
          await PrefsService.instance.salvarMedicamento(atualizado);
        }
      } catch (_) {}
    });
  }

  Future<void> _registrar(
    bool tomou,
    Map<String, dynamic> payload,
  ) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final historico = HistoricoModel(
        id: const Uuid().v4(),
        medicamentoId: payload['medicamentoId'] as String,
        userId: payload['userId'] as String,
        horarioAgendado:
            DateTime.parse(payload['horarioAgendado'] as String),
        horarioRegistro: DateTime.now(),
        tomou: tomou,
      );
      await MedicamentoRepository().registrarHistorico(historico);

      final medicamentoId = payload['medicamentoId'] as String;
      final horarioAgendado =
          DateTime.parse(payload['horarioAgendado'] as String);
      _agendarProxima(medicamentoId, horarioAgendado);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    Map<String, dynamic> payload = {};
    if (args is String) {
      try {
        payload = jsonDecode(args) as Map<String, dynamic>;
      } catch (_) {}
    }

    final nome = payload['nome'] as String? ?? 'Medicamento';
    final dosagem = payload['dosagem'] as String? ?? '';
    final horarioStr = payload['horarioAgendado'] as String?;
    final cor = payload.containsKey('colorValue')
        ? Color((payload['colorValue'] as num).toInt())
        : AppColors.primary;

    DateTime? horario;
    if (horarioStr != null) {
      try {
        horario = DateTime.parse(horarioStr);
      } catch (_) {}
    }

    final fmt = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Hora do Medicamento! 💊',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: cor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cor.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                nome,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dosagem,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              if (horario != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      fmt.format(horario),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _registrar(true, payload),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Tomei',
                  style: TextStyle(fontSize: 18),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _registrar(false, payload),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text(
                  'Cancelar / Pular',
                  style: TextStyle(fontSize: 18),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (_isProcessing) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
