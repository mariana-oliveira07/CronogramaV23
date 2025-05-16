import 'package:cronograma/data/models/turma_com_nomes.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../models/turma_model.dart';

class TurmaRepository {
  // Insert a new class and return its ID
  Future<int> insertTurma(Turma turma) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(
      'Turma',
      turma.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all classes with proper error handling
  Future<List<Turma>> getTurmas() async {
  try {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> turmaMaps = await db.query('Turma');
    return turmaMaps.map<Turma>((map) => Turma.fromMap(map)).toList();
  } catch (e) {
    throw Exception('Failed to load classes: $e');
  }
}

  // Get all classes with proper error handling
  Future<List<TurmaComNomes>> getTurmasNomes() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> turmaMaps = await db.rawQuery('''
      SELECT 
        t.*,
        c.nome_curso as nome_curso,
        i.nome_instrutor as nome_instrutor,
        tu.turno
      FROM Turma t
      JOIN Cursos c ON t.idCurso = c.idCurso
      JOIN Instrutores i ON t.idInstrutor = i.idInstrutor
      JOIN Turno tu ON tu.idTurno = t.idTurno
    ''');

      return turmaMaps
          .map<TurmaComNomes>((map) => TurmaComNomes.fromMap(map))
          .toList();
    } catch (e) {
      throw Exception('Failed to load classes: $e');
    }
  }
  
  // Get classes by course ID
  Future<List<Turma>> getTurmasByCurso(int cursoId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> results = await db.query(
      'Turma',
      where: 'idcurso = ?',
      whereArgs: [cursoId],
    );
    return results.map(Turma.fromMap).toList();
  }

  // Get classes by instructor ID
  Future<List<Turma>> getTurmasByInstrutor(int instrutorId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> results = await db.query(
      'Turma',
      where: 'idinstrutor = ?',
      whereArgs: [instrutorId],
    );
    return results.map(Turma.fromMap).toList();
  }

  // Update a class and return number of affected rows
  Future<int> updateTurma(Turma turma) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'Turma',
      turma.toMap(),
      where: 'idTurma = ?',
      whereArgs: [turma.idTurma],
    );
  }

  // Delete a class and return number of affected rows
  Future<int> deleteTurma(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'Turma',
      where: 'idTurma = ?',
      whereArgs: [id],
    );
  }

  // Get class details with joined information
  Future<List<Map<String, dynamic>>> getTurmasComDetalhes() async {
    final db = await DatabaseHelper.instance.database;
    return await db.rawQuery('''
      SELECT 
        Turma.*,
        Cursos.nome_curso as nome_curso,
        Instrutores.nome_instrutor as nome_instrutor,
        Turno.turno as turno
      FROM Turma
      JOIN Cursos ON Turma.idcurso = Cursos.idCursos
      JOIN Instrutores ON Turma.idinstrutor = Instrutores.idInstrutores
      JOIN Turno ON Turma.idturno = Turno.idTurno
      ORDER BY Turma.turma
    ''');
  }
}