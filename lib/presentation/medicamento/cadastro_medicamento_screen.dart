import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../data/medicamentos_lista.dart';
import '../../data/models/medicamento_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/medicamento_repository.dart';

class CadastroMedicamentoScreen extends StatefulWidget {
  final MedicamentoModel? medicamento;
  const CadastroMedicamentoScreen({super.key, this.medicamento});

  @override
  State<CadastroMedicamentoScreen> createState() =>
      _CadastroMedicamentoScreenState();
}

class _CadastroMedicamentoScreenState
    extends State<CadastroMedicamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _frequenciaCustomCtrl = TextEditingController();
  int _quantidade = 1;

  Color _corSelecionada = AppColors.medicamentoColors[0];
  int? _frequenciaHoras;
  bool _frequenciaCustom = false;
  DateTime? _dataInicio;
  DateTime? _dataFim;
  TimeOfDay? _horaInicio;
  bool _continuo = false;
  String _unidade = 'Comprimido';
  bool _isLoading = false;

  bool get _editando => widget.medicamento != null;

  static const _unidades = [
    'Comprimido',
    'Cápsula',
    'Gota',
    'ml',
    'mg',
    'Sachê',
    'Ampola',
    'Pomada',
    'Inalação',
    'Adesivo',
  ];

  final List<Map<String, dynamic>> _opcoesFrequencia = [
    {'label': 'A cada 4 horas', 'value': 4},
    {'label': 'A cada 6 horas', 'value': 6},
    {'label': 'A cada 8 horas', 'value': 8},
    {'label': 'A cada 12 horas', 'value': 12},
    {'label': 'Uma vez ao dia', 'value': 24},
    {'label': 'Personalizado', 'value': -1},
  ];

  @override
  void initState() {
    super.initState();
    final med = widget.medicamento;
    if (med != null) {
      _nomeCtrl.text = med.nome;
      _corSelecionada = Color(med.colorValue);
      _continuo = med.continuo;
      _dataInicio = med.dataInicio;
      _dataFim = med.dataFim;
      _horaInicio = TimeOfDay.fromDateTime(med.dataInicio);

      final parts = med.dosagem.split(' ');
      if (parts.length >= 2) {
        _quantidade = int.tryParse(parts[0]) ?? 1;
        final u = parts.sublist(1).join(' ');
        _unidade = _unidades.contains(u) ? u : 'Comprimido';
      }

      final freqsConhecidas = [4, 6, 8, 12, 24];
      if (freqsConhecidas.contains(med.frequenciaHoras)) {
        _frequenciaHoras = med.frequenciaHoras;
      } else {
        _frequenciaCustom = true;
        _frequenciaCustomCtrl.text = med.frequenciaHoras.toString();
      }
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _frequenciaCustomCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarData({required bool isInicio}) async {
    final hoje = DateTime.now();
    final inicial = isInicio
        ? (_dataInicio ?? hoje)
        : (_dataFim ?? (_dataInicio ?? hoje).add(const Duration(days: 1)));
    final picked = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: hoje,
      lastDate: hoje.add(const Duration(days: 365 * 2)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          final hora = _horaInicio ?? TimeOfDay.fromDateTime(hoje);
          _dataInicio = DateTime(
              picked.year, picked.month, picked.day, hora.hour, hora.minute);
          if (_dataFim != null && !_dataFim!.isAfter(_dataInicio!)) {
            _dataFim = null;
          }
        } else {
          _dataFim = DateTime(picked.year, picked.month, picked.day, 23, 59);
        }
      });
    }
  }

  Future<void> _selecionarHoraInicio() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaInicio ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _horaInicio = picked;
        if (_dataInicio != null) {
          _dataInicio = DateTime(_dataInicio!.year, _dataInicio!.month,
              _dataInicio!.day, picked.hour, picked.minute);
        }
      });
    }
  }

  String? _validarCampos() {
    if (_nomeCtrl.text.trim().isEmpty) return 'Informe o nome do medicamento.';
    if (_frequenciaHoras == null && !_frequenciaCustom) return 'Selecione a frequência.';
    if (_frequenciaCustom) {
      final v = int.tryParse(_frequenciaCustomCtrl.text.trim());
      if (v == null || v < 1) return 'Informe um intervalo válido em horas.';
    }
    if (_dataInicio == null) return 'Selecione a data de início.';
    if (_horaInicio == null) return 'Selecione a hora de início.';
    if (!_continuo && _dataFim == null) return 'Selecione a data de fim.';
    return null;
  }

  Future<void> _salvar() async {
    _formKey.currentState!.validate();
    final erro = _validarCampos();
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro), backgroundColor: AppColors.danger),
      );
      return;
    }

    final int horas = _frequenciaCustom
        ? int.parse(_frequenciaCustomCtrl.text.trim())
        : _frequenciaHoras!;

    final userId = await AuthRepository().obterSessaoAtiva();
    if (!mounted) return;
    if (userId == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final dosagem = '$_quantidade $_unidade';
    final repo = MedicamentoRepository();

    setState(() => _isLoading = true);
    try {
      if (_editando) {
        await repo.atualizarMedicamento(
          id: widget.medicamento!.id,
          userId: userId,
          nome: _nomeCtrl.text.trim(),
          dosagem: dosagem,
          cor: _corSelecionada,
          frequenciaHoras: horas,
          dataInicio: _dataInicio!,
          dataFim: _continuo ? null : _dataFim,
          continuo: _continuo,
        );
      } else {
        await repo.criarMedicamento(
          userId: userId,
          nome: _nomeCtrl.text.trim(),
          dosagem: dosagem,
          cor: _corSelecionada,
          frequenciaHoras: horas,
          dataInicio: _dataInicio!,
          dataFim: _continuo ? null : _dataFim,
          continuo: _continuo,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editando
                ? 'Medicamento atualizado com sucesso!'
                : 'Medicamento cadastrado com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _seletorCores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cor da embalagem',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: AppColors.medicamentoColors.map((cor) {
            final selecionada = cor == _corSelecionada;
            return GestureDetector(
              onTap: () => setState(() => _corSelecionada = cor),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cor,
                  shape: BoxShape.circle,
                  border: selecionada
                      ? Border.all(color: Colors.black87, width: 3)
                      : Border.all(color: Colors.grey.shade400, width: 1),
                  boxShadow: selecionada
                      ? [
                          BoxShadow(
                            color: cor.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: selecionada
                    ? Icon(
                        Icons.check,
                        color: cor == const Color(0xFFFAFAFA)
                            ? Colors.black54
                            : Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _stepperQuantidade() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quantidade', style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _quantidade > 1
                    ? () => setState(() => _quantidade--)
                    : null,
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$_quantidade',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _quantidade < 99
                    ? () => setState(() => _quantidade++)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _mostrarSeletorTipoAdministracao() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipo de administração',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _unidades.map((u) {
                final sel = u == _unidade;
                return ChoiceChip(
                  label: Text(u),
                  selected: sel,
                  onSelected: (_) {
                    setState(() => _unidade = u);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy', 'pt_BR');
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar Medicamento' : 'Novo Medicamento'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue v) {
                  if (v.text.length < 2) return const [];
                  final query = v.text.toLowerCase();
                  return medicamentosComuns
                      .where((m) => m.toLowerCase().contains(query))
                      .take(6);
                },
                onSelected: (s) => _nomeCtrl.text = s,
                fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) {
                  ctrl.addListener(() {
                    if (_nomeCtrl.text != ctrl.text) {
                      _nomeCtrl.text = ctrl.text;
                    }
                  });
                  return TextFormField(
                    controller: ctrl,
                    focusNode: focusNode,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome do medicamento',
                      prefixIcon: Icon(Icons.medication),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _stepperQuantidade(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tipo de administração',
                            style: TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.medication_outlined),
                          label: Text(_unidade),
                          onPressed: _mostrarSeletorTipoAdministracao,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _seletorCores(),
              const SizedBox(height: 24),

              DropdownButtonFormField<int>(
                initialValue: _frequenciaCustom ? -1 : _frequenciaHoras,
                decoration: const InputDecoration(
                  labelText: 'Frequência',
                  prefixIcon: Icon(Icons.repeat),
                  border: OutlineInputBorder(),
                ),
                items: _opcoesFrequencia
                    .map((o) => DropdownMenuItem<int>(
                          value: o['value'] as int,
                          child: Text(o['label'] as String),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    if (v == -1) {
                      _frequenciaCustom = true;
                      _frequenciaHoras = null;
                    } else {
                      _frequenciaCustom = false;
                      _frequenciaHoras = v;
                    }
                  });
                },
                validator: (v) {
                  if (v == null) return 'Selecione a frequência';
                  return null;
                },
              ),
              if (_frequenciaCustom) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _frequenciaCustomCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Intervalo em horas',
                    hintText: 'Ex: 3',
                    prefixIcon: Icon(Icons.timer),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (!_frequenciaCustom) return null;
                    if (v == null || v.isEmpty) return 'Campo obrigatório';
                    final h = int.tryParse(v);
                    if (h == null || h < 1) return 'Mínimo 1 hora';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),

              CheckboxListTile(
                value: _continuo,
                onChanged: (v) => setState(() {
                  _continuo = v ?? false;
                  if (_continuo) _dataFim = null;
                }),
                title: const Text('É um medicamento contínuo?'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _dataInicio == null
                            ? 'Data de início'
                            : fmt.format(_dataInicio!),
                      ),
                      onPressed: () => _selecionarData(isInicio: true),
                    ),
                  ),
                  if (!_continuo) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          _dataFim == null
                              ? 'Data de fim'
                              : fmt.format(_dataFim!),
                        ),
                        onPressed: _dataInicio == null
                            ? null
                            : () => _selecionarData(isInicio: false),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(
                  _horaInicio == null
                      ? 'Hora de início'
                      : _horaInicio!.format(context),
                ),
                onPressed: _selecionarHoraInicio,
              ),
              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: _isLoading ? null : _salvar,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text(
                  'Salvar Medicamento',
                  style: TextStyle(fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
