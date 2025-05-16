import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../models/estagio_model.dart';

class EstagioRepository {
  // Método para inserir um novo estágio (agora retorna o ID inserido)
  Future<int> insertEstagio(Estagio estagio) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(
      'Estagio',
      estagio.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Método para obter todos os estágios
  Future<List<Estagio>> getEstagios() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> estagioMaps = await db.query('Estagio');
    
    return estagioMaps.map((map) => Estagio.fromMap(map)).toList();
  }

  // Método para obter estágios por turma
  Future<List<Estagio>> getEstagiosPorTurma(int idTurma) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> estagioMaps = await db.query(
      'Estagio',
      where: 'idturma = ?',
      whereArgs: [idTurma],
    );
    
    return estagioMaps.map((map) => Estagio.fromMap(map)).toList();
  }

  // Método para atualizar um estágio (agora retorna número de linhas afetadas)
  Future<int> updateEstagio(Estagio estagio) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'Estagio',
      estagio.toMap(),
      where: 'idEstagio = ?',
      whereArgs: [estagio.idEstagio],
    );
  }

  // Método para deletar um estágio (agora retorna número de linhas afetadas)
  Future<int> deleteEstagio(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'Estagio',
      where: 'idEstagio = ?',
      whereArgs: [id],
    );
  }

  // Método para obter a duração total dos estágios de uma turma
  Future<int> getDuracaoTotalPorTurma(int idTurma) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(duracao) as total FROM Estagio WHERE idturma = ?',
      [idTurma],
    );
    
    return result.first['total'] as int? ?? 0;
  }
}