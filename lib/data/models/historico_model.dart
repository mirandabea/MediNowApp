class HistoricoModel {
  final String id;
  final String medicamentoId;
  final String userId;
  final DateTime horarioAgendado;
  final DateTime horarioRegistro;
  final bool tomou;

  const HistoricoModel({
    required this.id,
    required this.medicamentoId,
    required this.userId,
    required this.horarioAgendado,
    required this.horarioRegistro,
    required this.tomou,
  });

  factory HistoricoModel.fromJson(Map<String, dynamic> json) => HistoricoModel(
        id: json['id'] as String,
        medicamentoId: json['medicamentoId'] as String,
        userId: json['userId'] as String,
        horarioAgendado: DateTime.parse(json['horarioAgendado'] as String),
        horarioRegistro: DateTime.parse(json['horarioRegistro'] as String),
        tomou: json['tomou'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicamentoId': medicamentoId,
        'userId': userId,
        'horarioAgendado': horarioAgendado.toIso8601String(),
        'horarioRegistro': horarioRegistro.toIso8601String(),
        'tomou': tomou,
      };
}
