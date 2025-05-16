class Turma {
  final int? idTurma;
  final String turma;
  final int? idcurso;
  final int idturno;
  final int idinstrutor;
  final int? idUnidadeCurricular; // Adicione se necessário

  Turma({
    this.idTurma,
    required this.turma,
    this.idcurso,
    required this.idturno,
    required this.idinstrutor,
    this.idUnidadeCurricular,
  });

  factory Turma.fromMap(Map<String, dynamic> map) {
    return Turma(
      idTurma: safeParseInt(map['idTurma']),
      turma: map['turma']?.toString().trim() ?? '[Sem nome]',
      idcurso: safeParseInt(map['idcurso']),
      idturno: safeParseInt(map['idturno']) ?? 1, // Valor padrão 1
      idinstrutor: safeParseInt(map['idinstrutor']) ?? 0,
      idUnidadeCurricular: safeParseInt(map['idUnidadeCurricular']),
    );
  }

  static int? safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toMap() {
    return {
      'idTurma': idTurma,
      'turma': turma,
      'idcurso': idcurso,
      'idturno': idturno,
      'idinstrutor': idinstrutor,
      if (idUnidadeCurricular != null)
        'idUnidadeCurricular': idUnidadeCurricular,
    };
  }
}
