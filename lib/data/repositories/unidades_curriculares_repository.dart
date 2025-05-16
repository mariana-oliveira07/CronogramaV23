import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../models/unidades_curriculares_model.dart';

class UnidadesCurricularesRepository {
  // Insert a curriculum unit and return its ID
  Future<int> insertUnidadeCurricular(
      UnidadesCurriculares unidadeCurricular) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(
      'Unidades_Curriculares',
      unidadeCurricular.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all curriculum units with error handling
  Future<List<UnidadesCurriculares>> getUnidadesCurriculares() async {
    final db = await DatabaseHelper.instance.database;
    try {
      final List<Map<String, dynamic>> maps =
          await db.query('Unidades_Curriculares');
      return List.generate(maps.length, (i) {
        return UnidadesCurriculares(
          idUc: maps[i]['idUc'] as int,
          nomeUc: maps[i]['nome_uc'] as String,
          cargahoraria: maps[i]['cargahoraria'] as int,
          idcurso: maps[i]['idCurso'] as int,
        );
      });
    } catch (e) {
      throw Exception('Failed to load curriculum units: ${e.toString()}');
    }
  }

  // Get curriculum units by course ID
  Future<List<UnidadesCurriculares>> getUnidadesByCurso(int cursoId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> results = await db.query(
      'Unidades_Curriculares',
      where: 'idcurso = ?',
      whereArgs: [cursoId],
    );
    return results.map(UnidadesCurriculares.fromMap).toList();
  }

  // Update a curriculum unit and return number of affected rows
  Future<int> updateUnidadeCurricular(
      UnidadesCurriculares unidadeCurricular) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'Unidades_Curriculares',
      unidadeCurricular.toMap(),
      where: 'idUc = ?',
      whereArgs: [unidadeCurricular.idUc],
    );
  }

  // Delete a curriculum unit and return number of affected rows
  Future<int> deleteUnidadeCurricular(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'Unidades_Curriculares',
      where: 'idUc = ?',
      whereArgs: [id],
    );
  }

  // Get curriculum unit details with course information
  Future<List<Map<String, dynamic>>> getUnidadesComDetalhes() async {
    final db = await DatabaseHelper.instance.database;
    return await db.rawQuery('''
      SELECT 
        u.*,
        c.nome_curso as nome_curso
      FROM Unidades_Curriculares u
      JOIN Cursos c ON u.idcurso = c.idCursos
      ORDER BY u.nome_uc
    ''');
  }

  // Get total workload by course
  Future<int> getCargaHorariaTotalPorCurso(int cursoId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(cargahoraria) as total FROM Unidades_Curriculares WHERE idcurso = ?',
      [cursoId],
    );
    return result.first['total'] as int? ?? 0;
  }
}
