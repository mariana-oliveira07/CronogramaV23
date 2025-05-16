import 'package:cronograma/data/models/turma_model.dart' show Turma;

class TurmaComNomes {
  final int? idTurma;
  final String turma;
  final int? idcurso;
  final String nomeCurso; // Novo campo
  final int idturno;
  final int idinstrutor;
  final String nomeInstrutor; // Novo campo
  final int? idUnidadeCurricular;
  final String turno;

  TurmaComNomes(
      {this.idTurma,
      required this.turma,
      this.idcurso,
      required this.nomeCurso,
      required this.idturno,
      required this.idinstrutor,
      required this.nomeInstrutor,
      this.idUnidadeCurricular,
      required this.turno});

  factory TurmaComNomes.fromMap(Map<String, dynamic> map) {
    return TurmaComNomes(
      idTurma: Turma.safeParseInt(map['idTurma']),
      turma: map['turma']?.toString().trim() ?? '[Sem nome]',
      idcurso: Turma.safeParseInt(map['idCurso']),
      nomeCurso: map['nome_curso']?.toString().trim() ?? '[Sem nome]',
      idturno: Turma.safeParseInt(map['idturno']) ?? 1,
      idinstrutor: Turma.safeParseInt(map['idinstrutor']) ?? 0,
      nomeInstrutor: map['nome_instrutor']?.toString().trim() ?? '[Sem nome]',
      idUnidadeCurricular: Turma.safeParseInt(map['idUnidadeCurricular']),
      turno: map['turno']?.toString().trim() ?? '[Sem Turno]',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idTurma': idTurma,
      'turma': turma,
      'idcurso': idcurso,
      'nome_curso': nomeCurso,
      'idturno': idturno,
      'idinstrutor': idinstrutor,
      'nome_instrutor': nomeInstrutor,
      'turno': turno,
      if (idUnidadeCurricular != null)
        'idUnidadeCurricular': idUnidadeCurricular,
    };
  }
}
