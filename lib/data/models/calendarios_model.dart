class Calendarios {
  final int? idCalendarios;
  final int ano;
  final String mes;
  final String dataInicio;  // Formato: 'yyyy-MM-dd'
  final String dataFim;     // Formato: 'yyyy-MM-dd'
  final int idTurma;

  Calendarios({
    this.idCalendarios,
    required this.ano,
    required this.mes,
    required this.dataInicio,
    required this.dataFim,
    required this.idTurma,
  });

  // Adicione este factory constructor para conversão do Map para Objeto
  factory Calendarios.fromMap(Map<String, dynamic> map) {
    return Calendarios(
      idCalendarios: map['idCalendarios'] as int?,
      ano: map['ano'] as int,
      mes: map['mes'] as String,
      dataInicio: map['data_inicio'] as String,
      dataFim: map['data_fim'] as String,
      idTurma: map['idTurma'] as int,
    );
  }

  // Método para conversão do Objeto para Map
  Map<String, dynamic> toMap() {
    return {
      'idCalendarios': idCalendarios,
      'ano': ano,
      'mes': mes,
      'data_inicio': dataInicio,
      'data_fim': dataFim,
      'idTurma': idTurma,
    };
  }

  // Método opcional para formatação de datas no padrão brasileiro
  String get dataInicioFormatada {
    final date = DateTime.parse(dataInicio);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String get dataFimFormatada {
    final date = DateTime.parse(dataFim);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}