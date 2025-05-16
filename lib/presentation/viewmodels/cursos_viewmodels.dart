import '../../data/models/cursos_model.dart';
import '../../data/repositories/cursos_repository.dart';

class CursosViewModel {
  final CursosRepository repository;

  CursosViewModel(this.repository);

  Future<void> addCurso(Cursos curso) async {
    await repository.insertCurso(curso);
  }

  Future<List<Cursos>> getCursos() async {
    return await repository.getCursos();
  }

  Future<void> updateCurso(Cursos curso) async {
    await repository.updateCurso(curso);
  }

  Future<void> deleteCurso(int id) async {
    await repository.deleteCurso(id);
  }

  // Novo método para buscar o id do curso pelo nome
  Future<int?> getCursoIdByNome(String nomeCurso) async {
    return await repository.getCursoIdByNome(nomeCurso);
  }
}
