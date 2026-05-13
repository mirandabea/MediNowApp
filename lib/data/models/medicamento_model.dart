class MedicamentoModel {
  final String id;
  final String userId;
  final String nome;
  final String dosagem;
  final int colorValue;
  final int frequenciaHoras;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final bool continuo;
  final List<String> horariosAgendados;

  const MedicamentoModel({
    required this.id,
    required this.userId,
    required this.nome,
    required this.dosagem,
    required this.colorValue,
    required this.frequenciaHoras,
    required this.dataInicio,
    required this.dataFim,
    required this.continuo,
    required this.horariosAgendados,
  });

  MedicamentoModel copyWith({
    String? id,
    String? userId,
    String? nome,
    String? dosagem,
    int? colorValue,
    int? frequenciaHoras,
    DateTime? dataInicio,
    DateTime? dataFim,
    bool? continuo,
    List<String>? horariosAgendados,
  }) {
    return MedicamentoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nome: nome ?? this.nome,
      dosagem: dosagem ?? this.dosagem,
      colorValue: colorValue ?? this.colorValue,
      frequenciaHoras: frequenciaHoras ?? this.frequenciaHoras,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      continuo: continuo ?? this.continuo,
      horariosAgendados: horariosAgendados ?? this.horariosAgendados,
    );
  }

  factory MedicamentoModel.fromJson(Map<String, dynamic> json) => MedicamentoModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        nome: json['nome'] as String,
        dosagem: json['dosagem'] as String,
        colorValue: (json['colorValue'] as num).toInt(),
        frequenciaHoras: (json['frequenciaHoras'] as num).toInt(),
        dataInicio: DateTime.parse(json['dataInicio'] as String),
        dataFim: json['dataFim'] != null ? DateTime.parse(json['dataFim'] as String) : null,
        continuo: json['continuo'] as bool? ?? false,
        horariosAgendados: (json['horariosAgendados'] as List).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'nome': nome,
        'dosagem': dosagem,
        'colorValue': colorValue,
        'frequenciaHoras': frequenciaHoras,
        'dataInicio': dataInicio.toIso8601String(),
        'dataFim': dataFim?.toIso8601String(),
        'continuo': continuo,
        'horariosAgendados': horariosAgendados,
      };
}
