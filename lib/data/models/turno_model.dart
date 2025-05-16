class Turno {
  final int? idTurno;
  final String turno;  // Ex: 'Matutino', 'Vespertino', 'Noturno'

  Turno({
    this.idTurno,
    required this.turno,
  });

  // Factory constructor to create object from Map (database result)
  factory Turno.fromMap(Map<String, dynamic> map) {
    return Turno(
      idTurno: map['idTurno'] as int?,
      turno: map['turno'] as String,
    );
  }

  // Convert object to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'idTurno': idTurno,
      'turno': turno,
    };
  }

  // Get the start time of the shift
  String get horarioInicio {
    switch (turno.toLowerCase()) {
      case 'matutino':
        return '07:00';
      case 'vespertino':
        return '13:00';
      case 'noturno':
        return '19:00';
      default:
        return '08:00';
    }
  }

  // Get the end time of the shift
  String get horarioFim {
    switch (turno.toLowerCase()) {
      case 'matutino':
        return '12:00';
      case 'vespertino':
        return '18:00';
      case 'noturno':
        return '22:00';
      default:
        return '17:00';
    }
  }

  // Get shift duration in hours
  int get duracaoHoras {
    switch (turno.toLowerCase()) {
      case 'matutino':
        return 5;
      case 'vespertino':
        return 5;
      case 'noturno':
        return 3;
      default:
        return 4;
    }
  }

  // Helper method to display complete shift information
  String get infoTurno {
    return '$turno ($horarioInicio - $horarioFim)';
  }

  // Validate if the shift name is valid
  static bool isValid(String turno) {
    final validTurns = ['matutino', 'vespertino', 'noturno'];
    return validTurns.contains(turno.toLowerCase());
  }
}