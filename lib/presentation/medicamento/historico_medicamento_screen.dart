import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../data/models/historico_model.dart';
import '../../data/models/medicamento_model.dart';
import '../../data/local/prefs_service.dart';
import '../../domain/repositories/medicamento_repository.dart';

class HistoricoMedicamentoScreen extends StatefulWidget {
  final String medicamentoId;

  const HistoricoMedicamentoScreen({super.key, required this.medicamentoId});

  @override
  State<HistoricoMedicamentoScreen> createState() =>
      _HistoricoMedicamentoScreenState();
}

class _HistoricoMedicamentoScreenState
    extends State<HistoricoMedicamentoScreen> {
  MedicamentoModel? _medicamento;
  List<HistoricoModel> _historico = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _isLoading = true);
    try {
      final todos = await PrefsService.instance.listarTodosMedicamentos();
      MedicamentoModel? med;
      try {
        med = todos.firstWhere((m) => m.id == widget.medicamentoId);
      } catch (_) {
        med = null;
      }
      final historico = await MedicamentoRepository()
          .obterHistorico(widget.medicamentoId);
      if (mounted) {
        setState(() {
          _medicamento = med;
          _historico = historico;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');
    return Scaffold(
      appBar: AppBar(
        title: Text(_medicamento?.nome ?? 'Histórico'),
        backgroundColor: _medicamento != null
            ? Color(_medicamento!.colorValue)
            : AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_medicamento != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Color(_medicamento!.colorValue).withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color(_medicamento!.colorValue),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.medication,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _medicamento!.nome,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _medicamento!.dosagem,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _historico.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Nenhum registro ainda',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _historico.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final h = _historico[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: h.tomou
                                    ? AppColors.success.withValues(alpha: 0.15)
                                    : AppColors.danger.withValues(alpha: 0.15),
                                child: Icon(
                                  h.tomou
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: h.tomou
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
                              ),
                              title: Text(
                                h.tomou ? 'Tomei' : 'Pulei / Cancelei',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: h.tomou
                                      ? AppColors.success
                                      : AppColors.danger,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Agendado: ${fmt.format(h.horarioAgendado)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    'Respondido: ${fmt.format(h.horarioRegistro)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
