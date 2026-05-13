import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/notification_service.dart';
import '../../data/local/prefs_service.dart';
import '../../data/models/historico_model.dart';
import '../../data/models/medicamento_model.dart';

class MedicamentoRepository {
  final PrefsService _prefs = PrefsService.instance;

  Future<void> criarMedicamento({
    required String userId,
    required String nome,
    required String dosagem,
    required Color cor,
    required int frequenciaHoras,
    required DateTime dataInicio,
    required DateTime? dataFim,
    required bool continuo,
  }) async {
    final med = MedicamentoModel(
      id: const Uuid().v4(),
      userId: userId,
      nome: nome,
      dosagem: dosagem,
      colorValue: cor.toARGB32(),
      frequenciaHoras: frequenciaHoras,
      dataInicio: dataInicio,
      dataFim: dataFim,
      continuo: continuo,
      horariosAgendados: [],
    );
    final isos = await NotificationService.agendarJanela(med);
    await _prefs.salvarMedicamento(med.copyWith(horariosAgendados: isos));
  }

  Future<List<MedicamentoModel>> listarMedicamentos(String userId) =>
      _prefs.listarMedicamentosDoUsuario(userId);

  Future<void> atualizarMedicamento({
    required String id,
    required String userId,
    required String nome,
    required String dosagem,
    required Color cor,
    required int frequenciaHoras,
    required DateTime dataInicio,
    required DateTime? dataFim,
    required bool continuo,
  }) async {
    await NotificationService.cancelarMedicamento(id);
    final med = MedicamentoModel(
      id: id,
      userId: userId,
      nome: nome,
      dosagem: dosagem,
      colorValue: cor.toARGB32(),
      frequenciaHoras: frequenciaHoras,
      dataInicio: dataInicio,
      dataFim: dataFim,
      continuo: continuo,
      horariosAgendados: [],
    );
    final isos = await NotificationService.agendarJanela(med);
    await _prefs.salvarMedicamento(med.copyWith(horariosAgendados: isos));
  }

  Future<void> deletarMedicamento(String medicamentoId) async {
    await NotificationService.cancelarMedicamento(medicamentoId);
    await _prefs.deletarMedicamento(medicamentoId);
  }

  Future<void> reagendarTodos(String userId) async {
    final meds = await listarMedicamentos(userId);
    for (final med in meds) {
      await NotificationService.cancelarMedicamento(med.id);
      final isos = await NotificationService.agendarJanela(med);
      await _prefs.salvarMedicamento(med.copyWith(horariosAgendados: isos));
    }
  }

  Future<void> registrarHistorico(HistoricoModel h) =>
      _prefs.salvarHistorico(h);

  Future<List<HistoricoModel>> obterHistorico(String medicamentoId) =>
      _prefs.listarHistorico(medicamentoId);
}
