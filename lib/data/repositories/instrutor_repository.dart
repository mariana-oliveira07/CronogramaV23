import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../models/instrutores_model.dart';

class InstrutoresRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Insert an instructor and return the new ID
  Future<int> insertInstrutor(Instrutores instrutor) async {
    final db = await _databaseHelper.database;
    try {
      return await db.insert(
        'Instrutores',
        instrutor.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to insert instructor: ${e.toString()}');
    }
  }

  // Get all instructors with proper error handling
  Future<List<Instrutores>> getInstrutores() async {
    final db = await _databaseHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('Instrutores');
      return List.generate(maps.length, (i) {
        return Instrutores.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Failed to load instructors: ${e.toString()}');
    }
  }

  // Update an instructor and return number of affected rows
  Future<int> updateInstrutor(Instrutores instrutor) async {
    final db = await _databaseHelper.database;
    try {
      return await db.update(
        'Instrutores',
        instrutor.toMap(),
        where:
            'idInstrutor = ?', // Corrigido para usar o nome correto da coluna
        whereArgs: [instrutor.idInstrutor],
      );
    } catch (e) {
      throw Exception('Failed to update instructor: ${e.toString()}');
    }
  }

  // Delete an instructor and return number of affected rows
  Future<int> deleteInstrutor(int id) async {
    final db = await _databaseHelper.database;
    try {
      return await db.delete(
        'Instrutores',
        where:
            'idInstrutor = ?', // Corrigido para usar o nome correto da coluna
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete instructor: ${e.toString()}');
    }
  }

  // Get instructor ID by name (optimized)
  Future<int?> getInstrutorIdByNome(String nomeInstrutor) async {
    final db = await _databaseHelper.database;
    try {
      final List<Map<String, dynamic>> result = await db.query(
        'Instrutores',
        columns: [
          'idInstrutor'
        ], // Corrigido para usar o nome correto da coluna
        where: 'nome_instrutor = ?',
        whereArgs: [nomeInstrutor],
        limit: 1,
      );
      return result.isNotEmpty ? result.first['idInstrutor'] as int? : null;
    } catch (e) {
      throw Exception('Failed to get instructor ID: ${e.toString()}');
    }
  }

  // Check if instructor exists by name
  Future<bool> instrutorExists(String nomeInstrutor) async {
    final db = await _databaseHelper.database;
    try {
      final result = await db.rawQuery(
        'SELECT EXISTS(SELECT 1 FROM Instrutores WHERE nome_instrutor = ? LIMIT 1)',
        [nomeInstrutor],
      );
      return result.isNotEmpty && result.first.values.first == 1;
    } catch (e) {
      throw Exception('Failed to check instructor existence: ${e.toString()}');
    }
  }

  // Get instructors by specialization
  Future<List<Instrutores>> getInstrutoresByEspecializacao(
      String especializacao) async {
    final db = await _databaseHelper.database;
    try {
      final List<Map<String, dynamic>> results = await db.query(
        'Instrutores',
        where: 'especializacao = ?',
        whereArgs: [especializacao],
      );
      return results.map((map) => Instrutores.fromMap(map)).toList();
    } catch (e) {
      throw Exception(
          'Failed to get instructors by specialization: ${e.toString()}');
    }
  }
}
