import 'package:cronograma/core/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import '../models/calendarios_model.dart';

class CalendariosRepository {
  // Método para inserir um novo calendário
  Future<void> insertCalendario(Calendarios calendario) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'Calendarios',
      calendario.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Método para obter todos os calendários
  Future<List<Calendarios>> getCalendarios() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> calendarioMaps = await db.query('Calendarios');
    
    return calendarioMaps.map((map) {
      return Calendarios(
        idCalendarios: map['idCalendarios'] as int?,
        ano: map['ano'] as int,
        mes: map['mes'] as String,
        dataInicio: DatabaseHelper.formatarParaBrasil(DateTime.parse(map['data_inicio'] as String)),
        dataFim: DatabaseHelper.formatarParaBrasil(DateTime.parse(map['data_fim'] as String)),
        idTurma: map['idturma'] as int,
      );
    }).toList();
  }

  // Método para atualizar um calendário existente
  Future<void> updateCalendario(Calendarios calendario) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'Calendarios',
      {
        ...calendario.toMap(),
        'data_inicio': DatabaseHelper.formatarParaBanco(DateTime.parse(calendario.dataInicio)),
        'data_fim': DatabaseHelper.formatarParaBanco(DateTime.parse(calendario.dataFim)),
      },
      where: 'idCalendarios = ?',
      whereArgs: [calendario.idCalendarios],
    );
  }

  // Método para deletar um calendário
  Future<void> deleteCalendario(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'Calendarios',
      where: 'idCalendarios = ?',
      whereArgs: [id],
    );
  }

  // Método adicional para buscar calendários por turma
  Future<List<Calendarios>> getCalendariosPorTurma(int idTurma) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> calendarioMaps = await db.query(
      'Calendarios',
      where: 'idturma = ?',
      whereArgs: [idTurma],
    );
    
    return calendarioMaps.map((map) {
      return Calendarios(
        idCalendarios: map['idCalendarios'] as int?,
        ano: map['ano'] as int,
        mes: map['mes'] as String,
        dataInicio: DatabaseHelper.formatarParaBrasil(DateTime.parse(map['data_inicio'] as String)),
        dataFim: DatabaseHelper.formatarParaBrasil(DateTime.parse(map['data_fim'] as String)),
        idTurma: map['idturma'] as int,
      );
    }).toList();
  }
}