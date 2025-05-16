class UnidadesCurriculares {
  final int? idUc;
  final String nomeUc;
  final int cargahoraria; // in hours
  final int idcurso;

  UnidadesCurriculares({
    this.idUc,
    required this.nomeUc,
    required this.cargahoraria,
    required this.idcurso,
  });

  // Factory constructor to create object from Map (database result)
  factory UnidadesCurriculares.fromMap(Map<String, dynamic> map) {
    return UnidadesCurriculares(
      idUc: map['idUc'] as int?,
      nomeUc: map['nome_uc'] as String,
      cargahoraria: map['cargahoraria'] as int,
      idcurso: map['idcurso'] as int,
    );
  }

  // Convert object to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'idUc': idUc,
      'nome_uc': nomeUc,
      'cargahoraria': cargahoraria,
      'idcurso': idcurso,
    };
  }

  // Format workload for display (e.g., "60 horas")
  String get cargaHorariaFormatada => '$cargahoraria horas';

  // Check if this is an intensive course unit
  bool get isIntensiva => cargahoraria > 60; // More than 60 hours

  // Get the estimated duration in weeks (assuming 4h/week)
  int get duracaoEstimadaSemanas => (cargahoraria / 4).ceil();

  // Helper method to display complete information
  String get infoCompleta {
    return '''
    Unidade Curricular: $nomeUc
    Carga Horária: $cargaHorariaFormatada
    Duração Estimada: $duracaoEstimadaSemanas semanas
    ${isIntensiva ? '(Curso Intensivo)' : ''}
    ''';
  }

  // Validate course unit data
  static bool validate({
    required String nomeUc,
    required int cargahoraria,
  }) {
    return nomeUc.length >= 5 && cargahoraria > 0;
  }
}