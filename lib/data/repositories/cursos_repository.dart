import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../models/cursos_model.dart';

class CursosRepository {
  // Método para inserir um novo curso
  Future<int> insertCurso(Cursos curso) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(
      'Cursos',
      curso.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Método para obter todos os cursos
  Future<List<Cursos>> getCursos() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> cursoMaps = await db.query('Cursos');

    return cursoMaps.map((map) {
      return Cursos(
        idCurso: map['idCurso']
            as int?, // Verifique se este nome corresponde ao nome real da coluna
        nomeCurso: map['nome_curso'] as String,
        cargahoraria: map['cargahoraria'] as int,
      );
    }).toList();
  }

  // Método para atualizar um curso existente
  Future<int> updateCurso(Cursos curso) async {
    final db = await DatabaseHelper.instance.database;
    if (curso.idCurso == null) {
      throw Exception("ID do curso não pode ser nulo.");
    }

    return await db.update(
      'Cursos',
      curso.toMap(),
      where: 'idCurso = ?', // Ajuste se necessário
      whereArgs: [curso.idCurso],
    );
  }

  // Método para deletar um curso
  Future<int> deleteCurso(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'Cursos',
      where: 'idCurso = ?', // ajuste se necessário
      whereArgs: [id],
    );
  }

  // Método para obter ID do curso pelo nome
  Future<int?> getCursoIdByNome(String nomeCurso) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.query(
      'Cursos',
      columns: ['idCurso'], // ajuste se necessário
      where: 'nome_curso = ?',
      whereArgs: [nomeCurso],
      limit: 1,
    );

    return result.isNotEmpty
        ? result.first['idCurso'] as int?
        : null; // Verifique o nome da coluna
  }

  // Método adicional: buscar cursos por carga horária mínima
  Future<List<Cursos>> getCursosPorCargaHoraria(int cargaMinima) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> cursoMaps =
        await db.query('Cursos', where: 'cargahoraria >= ?', whereArgs: [
      cargaMinima,
    ]);

    return cursoMaps.map((map) => Cursos.fromMap(map)).toList();
  }
}
