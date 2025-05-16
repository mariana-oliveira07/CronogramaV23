import '../../data/models/instrutores_model.dart';
import '../../data/repositories/instrutor_repository.dart';

class InstrutoresViewModel {
  final InstrutoresRepository repository;

  InstrutoresViewModel(this.repository);

  Future<void> addInstrutor(Instrutores instrutor) async {
    await repository.insertInstrutor(instrutor);
  }

  Future<List<Instrutores>> getInstrutores() async {
    return await repository.getInstrutores();
  }

  Future<void> updateInstrutor(Instrutores instrutor) async {
    await repository.updateInstrutor(instrutor);
  }

  Future<void> deleteInstrutor(int? id) async {
    await repository.deleteInstrutor(id!);
  }

  Future<int?> getInstrutorIdByNome(String nomeInstrutor) async {
    return await repository.getInstrutorIdByNome(nomeInstrutor);
  }
}
