class Cursos {
  final int? idCurso;
  final String nomeCurso;
  final int cargahoraria;

  const Cursos({
    this.idCurso,
    required this.nomeCurso,
    required this.cargahoraria,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cursos && other.idCurso == idCurso;
  }

  @override
  int get hashCode => idCurso.hashCode;
  // Factory constructor for creating from database maps
  factory Cursos.fromMap(Map<String, dynamic> map) {
    return Cursos(
      idCurso: map['idCurso'] as int?,
      nomeCurso: map['nome_curso'] as String,
      cargahoraria: map['cargahoraria'] as int,
    );
  }

  // Convert to map for database operations
  Map<String, dynamic> toMap() {
    return {
      'idCurso': idCurso,
      'nome_curso': nomeCurso,
      'cargahoraria': cargahoraria,
    };
  }

  // Format workload for display (e.g., "1200 horas")
  String get cargaHorariaFormatada => '$cargahoraria horas';

  // Categorize course by workload
  String get categoria {
    if (cargahoraria >= 1200) return 'Técnico';
    if (cargahoraria >= 400) return 'Certificação';
    return 'Curta Duração';
  }

  // Estimated duration in months (assuming 80h/month)
  int get duracaoEstimadaMeses => (cargahoraria / 80).ceil();

  // Complete course information
  String get infoCurso {
    return '''
    Curso: $nomeCurso
    Carga Horária: $cargaHorariaFormatada
    Categoria: $categoria
    Duração Estimada: $duracaoEstimadaMeses meses
    ''';
  }

  // Validate course data
  static bool validar({
    required String nome,
    required int cargaHoraria,
  }) {
    return nome.length >= 5 && cargaHoraria > 0;
  }

  // Helper to create short description
  String get descricaoResumida => '$nomeCurso ($categoria)';
}
