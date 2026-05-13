import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../data/models/medicamento_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/medicamento_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userId;
  String? _nomeUsuario;
  List<MedicamentoModel> _medicamentos = [];
  bool _isLoading = true;
  bool _carregamentoInicial = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    if (_carregamentoInicial) setState(() => _isLoading = true);
    try {
      final authRepo = AuthRepository();
      final userId = await authRepo.obterSessaoAtiva();
      if (!mounted) return;
      if (userId == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      final usuario = await authRepo.obterUsuarioDaSessao();
      final meds = await MedicamentoRepository().listarMedicamentos(userId);
      if (!mounted) return;
      setState(() {
        _userId = userId;
        _nomeUsuario = usuario?.nome ?? 'Usuário';
        _medicamentos = meds;
        _isLoading = false;
        _carregamentoInicial = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja encerrar sua sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthRepository().logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _deletarMedicamento(MedicamentoModel med) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover medicamento'),
        content: Text('Deseja remover "${med.nome}"? As notificações serão canceladas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await MedicamentoRepository().deletarMedicamento(med.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicamento removido.')),
          );
          _carregarDados();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao remover: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  String _proximoHorario(MedicamentoModel med) {
    final agora = DateTime.now();
    for (final iso in med.horariosAgendados) {
      final horario = DateTime.parse(iso);
      if (horario.isAfter(agora)) {
        return DateFormat("dd/MM 'às' HH:mm", 'pt_BR').format(horario);
      }
    }
    return 'Concluído';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${_nomeUsuario ?? ''}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: _medicamentos.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.medication_outlined,
                                size: 80,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Nenhum medicamento cadastrado',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Toque no + para adicionar',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _medicamentos.length,
                      itemBuilder: (context, index) {
                        final med = _medicamentos[index];
                        final cor = Color(med.colorValue);
                        final proximoH = _proximoHorario(med);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/historico',
                              arguments: med.id,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: cor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.medication,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          med.nome,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          med.dosagem,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Próximo: $proximoH',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: Colors.grey),
                                    onPressed: () async {
                                      await Navigator.pushNamed(
                                        context,
                                        '/cadastro-medicamento',
                                        arguments: med,
                                      );
                                      _carregarDados();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.grey),
                                    onPressed: () => _deletarMedicamento(med),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/cadastro-medicamento',
              arguments: _userId);
          _carregarDados();
        },
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
