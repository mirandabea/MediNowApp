import 'package:uuid/uuid.dart';
import '../../core/utils/hash_util.dart';
import '../../data/local/prefs_service.dart';
import '../../data/models/user_model.dart';

class AuthRepository {
  final PrefsService _prefs = PrefsService.instance;

  Future<String?> cadastrar({
    required String nome,
    required String telefone,
    required String senha,
    required int idade,
    required String sexo,
  }) async {
    final existente = await _prefs.buscarUsuarioPorTelefone(telefone);
    if (existente != null) return 'Telefone já cadastrado.';

    final user = UserModel(
      id: const Uuid().v4(),
      nome: nome,
      telefone: telefone,
      senhaHash: HashUtil.sha256Of(senha),
      idade: idade,
      sexo: sexo,
    );

    await _prefs.salvarUsuario(user);
    await _prefs.salvarSessao(user.id);
    return null;
  }

  Future<UserModel> login({
    required String telefone,
    required String senha,
  }) async {
    final user = await _prefs.buscarUsuarioPorTelefone(telefone);
    if (user == null) throw Exception('Usuário não encontrado.');
    if (user.senhaHash != HashUtil.sha256Of(senha)) {
      throw Exception('Senha incorreta.');
    }
    await _prefs.salvarSessao(user.id);
    return user;
  }

  Future<void> logout() async => _prefs.encerrarSessao();

  Future<String?> obterSessaoAtiva() => _prefs.obterSessaoAtiva();

  Future<UserModel?> obterUsuarioDaSessao() async {
    final id = await _prefs.obterSessaoAtiva();
    if (id == null) return null;
    return _prefs.buscarUsuarioPorId(id);
  }
}
