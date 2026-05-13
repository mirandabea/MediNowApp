import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/medicamento_model.dart';
import '../models/historico_model.dart';

class PrefsService {
  PrefsService._();
  static final PrefsService instance = PrefsService._();

  static const _keyUsers = 'medinow_users';
  static const _keyMedicamentos = 'medinow_medicamentos';
  static const _keyHistoricos = 'medinow_historicos';
  static const _keySessao = 'medinow_sessao_usuario_id';
  static const _keyPendingNotif = 'medinow_pending_notification';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> salvarSessao(String userId) async {
    final prefs = await _prefs;
    await prefs.setString(_keySessao, userId);
  }

  Future<String?> obterSessaoAtiva() async {
    final prefs = await _prefs;
    return prefs.getString(_keySessao);
  }

  Future<void> encerrarSessao() async {
    final prefs = await _prefs;
    await prefs.remove(_keySessao);
  }

  Future<List<UserModel>> listarUsuarios() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyUsers) ?? '[]';
    final List lista = jsonDecode(raw);
    return lista.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> salvarUsuario(UserModel user) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyUsers) ?? '[]';
    final List lista = jsonDecode(raw);
    final index = lista.indexWhere((e) => (e as Map)['id'] == user.id);
    if (index >= 0) {
      lista[index] = user.toJson();
    } else {
      lista.add(user.toJson());
    }
    await prefs.setString(_keyUsers, jsonEncode(lista));
  }

  Future<UserModel?> buscarUsuarioPorTelefone(String telefone) async {
    final usuarios = await listarUsuarios();
    try {
      return usuarios.firstWhere((u) => u.telefone == telefone);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> buscarUsuarioPorId(String id) async {
    final usuarios = await listarUsuarios();
    try {
      return usuarios.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<MedicamentoModel>> listarTodosMedicamentos() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyMedicamentos) ?? '[]';
    final List lista = jsonDecode(raw);
    return lista.map((e) => MedicamentoModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MedicamentoModel>> listarMedicamentosDoUsuario(String userId) async {
    final todos = await listarTodosMedicamentos();
    return todos.where((m) => m.userId == userId).toList();
  }

  Future<void> salvarMedicamento(MedicamentoModel med) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyMedicamentos) ?? '[]';
    final List lista = jsonDecode(raw);
    final index = lista.indexWhere((e) => (e as Map)['id'] == med.id);
    if (index >= 0) {
      lista[index] = med.toJson();
    } else {
      lista.add(med.toJson());
    }
    await prefs.setString(_keyMedicamentos, jsonEncode(lista));
  }

  Future<void> deletarMedicamento(String medicamentoId) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyMedicamentos) ?? '[]';
    final List lista = jsonDecode(raw);
    lista.removeWhere((e) => (e as Map)['id'] == medicamentoId);
    await prefs.setString(_keyMedicamentos, jsonEncode(lista));
  }

  Future<List<HistoricoModel>> listarHistorico(String medicamentoId) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyHistoricos) ?? '[]';
    final List lista = jsonDecode(raw);
    return lista
        .map((e) => HistoricoModel.fromJson(e as Map<String, dynamic>))
        .where((h) => h.medicamentoId == medicamentoId)
        .toList()
      ..sort((a, b) => b.horarioAgendado.compareTo(a.horarioAgendado));
  }

  Future<void> salvarHistorico(HistoricoModel h) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyHistoricos) ?? '[]';
    final List lista = jsonDecode(raw);
    lista.add(h.toJson());
    await prefs.setString(_keyHistoricos, jsonEncode(lista));
  }

  Future<void> salvarNotificacaoPendente(String payload) async {
    final prefs = await _prefs;
    await prefs.setString(_keyPendingNotif, payload);
  }

  Future<String?> consumirNotificacaoPendente() async {
    final prefs = await _prefs;
    final payload = prefs.getString(_keyPendingNotif);
    if (payload != null) {
      await prefs.remove(_keyPendingNotif);
    }
    return payload;
  }
}
