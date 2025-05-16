import '../../data/models/calendarios_model.dart';
import '../../data/repositories/calendarios_repository.dart';

class CalendariosViewModel {
  final CalendariosRepository repository;

  CalendariosViewModel(this.repository);

  Future<void> addCalendario(Calendarios calendario) async {
    await repository.insertCalendario(calendario);
  }

  Future<List<Calendarios>> getCalendarios() async {
    return await repository.getCalendarios();
  }

  Future<void> updateCalendario(Calendarios calendario) async {
    await repository.updateCalendario(calendario);
  }

  Future<void> deleteCalendario(int id) async {
    await repository.deleteCalendario(id);
  }
}
