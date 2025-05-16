import '../../data/models/unidades_curriculares_model.dart';
import '../../data/repositories/unidades_curriculares_repository.dart';

class UnidadesCurricularesViewModel {
  final UnidadesCurricularesRepository repository;

  UnidadesCurricularesViewModel(this.repository);

  Future<void> addUnidadeCurricular(
      UnidadesCurriculares unidadeCurricular) async {
    await repository.insertUnidadeCurricular(unidadeCurricular);
  }

  Future<List<UnidadesCurriculares>> getUnidadesCurriculares() async {
    try {
      return await repository.getUnidadesCurriculares();
    } catch (e) {
      throw Exception('Error loading curriculum units: ${e.toString()}');
    }
  }

  Future<void> updateUnidadeCurricular(
      UnidadesCurriculares unidadeCurricular) async {
    await repository.updateUnidadeCurricular(unidadeCurricular);
  }

  Future<void> deleteUnidadeCurricular(int id) async {
    await repository.deleteUnidadeCurricular(id);
  }
}
