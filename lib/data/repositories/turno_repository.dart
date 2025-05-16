import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../models/turno_model.dart';

class TurnoRepository {
  // Insert a shift and return its ID
  Future<int> insertTurno(Turno turno) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(
      'Turno',
      turno.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all shifts with error handling
  Future<List<Turno>> getTurnos() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> turnoMaps = await db.query('Turno');
      return turnoMaps.map(Turno.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to load shifts: $e');
    }
  }

  // Update a shift and return number of affected rows
  Future<int> updateTurno(Turno turno) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'Turno',
      turno.toMap(),
      where: 'idTurno = ?',
      whereArgs: [turno.idTurno],
    );
  }

  // Delete a shift and return number of affected rows
  Future<int> deleteTurno(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'Turno',
      where: 'idTurno = ?',
      whereArgs: [id],
    );
  }

  // Get shift ID by name (optimized version)
  Future<int?> getTurnoIdByNome(String nomeTurno) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.query(
      'Turno',
      columns: ['idTurno'],
      where: 'turno = ?',
      whereArgs: [nomeTurno],
      limit: 1,
    );
    
    return result.isNotEmpty ? result.first['idTurno'] as int? : null;
  }

  // Check if shift exists by name
  Future<bool> turnoExists(String nomeTurno) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT 1 FROM Turno WHERE turno = ? LIMIT 1',
      [nomeTurno],
    );
    return result.isNotEmpty;
  }

  // Get shift name by ID
  Future<String?> getTurnoNameById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'Turno',
      columns: ['turno'],
      where: 'idTurno = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['turno'] as String? : null;
  }
}