import '../../data/models/turno_model.dart';
import '../../data/repositories/turno_repository.dart';

class TurnoViewModel {
  final TurnoRepository repository;

  TurnoViewModel(this.repository);

  Future<void> addTurno(Turno turno) async {
    await repository.insertTurno(turno);
  }

  Future<List<Turno>> getTurnos() async {
    return await repository.getTurnos();
  }

  Future<void> updateTurno(Turno turno) async {
    await repository.updateTurno(turno);
  }

  Future<void> deleteTurno(int id) async {
    await repository.deleteTurno(id);
  }

  Future<int?> getTurnoIdByNome(String nomeTurno) async {
    return await repository.getTurnoIdByNome(nomeTurno);
  }
}
