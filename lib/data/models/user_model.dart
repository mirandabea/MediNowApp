class UserModel {
  final String id;
  final String nome;
  final String telefone;
  final String senhaHash;
  final int idade;
  final String sexo;

  const UserModel({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.senhaHash,
    required this.idade,
    required this.sexo,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        nome: json['nome'] as String,
        telefone: json['telefone'] as String,
        senhaHash: json['senhaHash'] as String,
        idade: (json['idade'] as num).toInt(),
        sexo: json['sexo'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'telefone': telefone,
        'senhaHash': senhaHash,
        'idade': idade,
        'sexo': sexo,
      };
}
