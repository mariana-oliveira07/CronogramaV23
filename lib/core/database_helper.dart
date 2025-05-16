import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static const _databaseName = 'education_database.db';
  static const _databaseVersion = 4; // Aumentei a versão para 4

  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._internal();

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static String formatarParaBanco(DateTime data) {
    return DateFormat('yyyy-MM-dd').format(data);
  }

  static String formatarParaBrasil(DateTime data) {
    return DateFormat('dd/MM/yyyy').format(data);
  }

  static DateTime? parseDataBrasileira(String dataStr) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dataStr);
    } catch (e) {
      return null;
    }
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Cursos (
        idCurso INTEGER PRIMARY KEY AUTOINCREMENT,
        nome_curso TEXT NOT NULL,
        cargahoraria INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE Turno (
        idTurno INTEGER PRIMARY KEY AUTOINCREMENT,
        turno TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE Instrutores (
        idInstrutor INTEGER PRIMARY KEY AUTOINCREMENT,
        nome_instrutor TEXT NOT NULL,
        especializacao TEXT,
        email TEXT,
        telefone TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE Unidades_Curriculares (
        idUc INTEGER PRIMARY KEY AUTOINCREMENT,
        nome_uc TEXT NOT NULL,
        cargahoraria INTEGER,
        idCurso INTEGER,
        FOREIGN KEY (idCurso) REFERENCES Cursos(idCurso)
      );
    ''');

    await db.execute('''
      CREATE TABLE Turma (
        idTurma INTEGER PRIMARY KEY AUTOINCREMENT,
        turma TEXT NOT NULL,
        idCurso INTEGER NOT NULL,
        idInstrutor INTEGER NOT NULL,
        idTurno INTEGER NOT NULL,
        FOREIGN KEY (idCurso) REFERENCES Cursos(idCurso),
        FOREIGN KEY (idInstrutor) REFERENCES Instrutores(idInstrutor),
        FOREIGN KEY (idTurno) REFERENCES Turno(idTurno)
      );
    ''');

    await db.execute('''
      CREATE TABLE Aulas (
        idAula INTEGER PRIMARY KEY AUTOINCREMENT,
        idUc INTEGER NOT NULL,
        idTurma INTEGER NOT NULL,
        data TEXT NOT NULL,
        horario TEXT NOT NULL,
        status TEXT DEFAULT 'Agendada',
        observacoes TEXT,
        horas INTEGER DEFAULT 1,
        FOREIGN KEY (idUc) REFERENCES Unidades_Curriculares(idUc),
        FOREIGN KEY (idTurma) REFERENCES Turma(idTurma)
      );
    ''');

    await _insertInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Aulas (
          idAula INTEGER PRIMARY KEY AUTOINCREMENT,
          idUc INTEGER NOT NULL,
          idTurma INTEGER NOT NULL,
          data TEXT NOT NULL,
          horario TEXT NOT NULL,
          status TEXT DEFAULT 'Agendada',
          observacoes TEXT,
          FOREIGN KEY (idUc) REFERENCES Unidades_Curriculares(idUc),
          FOREIGN KEY (idTurma) REFERENCES Turma(idTurma)
        );
      ''');
    }

    if (oldVersion < 3) {
      try {
        await db.execute(
            'ALTER TABLE Unidades_Curriculares ADD COLUMN cargahoraria INTEGER DEFAULT 0');
      } catch (e) {
        // Ignora se a coluna já existir
      }
    }

    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE Aulas ADD COLUMN horas INTEGER DEFAULT 1');
      } catch (e) {
        // Ignora se a coluna já existir
      }
    }
  }


  Future<void> _insertInitialData(Database db) async {
    await db.insert('Turno', {'turno': 'Matutino'});
    await db.insert('Turno', {'turno': 'Vespertino'});
    await db.insert('Turno', {'turno': 'Noturno'});

    await db.insert('Cursos',
        {'nome_curso': 'Técnico em Informática', 'cargahoraria': 1200});
    await db.insert('Cursos',
        {'nome_curso': 'Técnico em Administração', 'cargahoraria': 1000});

    await db.insert('Instrutores', {
      'nome_instrutor': 'Prof. Silva',
      'especializacao': 'Programação',
      'email': 'silva@escola.com',
      'telefone': '(11) 99999-9999'
    });
  }

  Future<List<Map<String, dynamic>>> getAulasComDetalhes() async {
    final db = await database;
    final aulas = await db.rawQuery('''
      SELECT 
        Aulas.*,
        Unidades_Curriculares.nome_uc,
        Turma.turma,
        Cursos.nome_curso,
        Instrutores.nome_instrutor,
        Turno.turno
      FROM Aulas
      JOIN Unidades_Curriculares ON Aulas.idUc = Unidades_Curriculares.idUc
      JOIN Turma ON Aulas.idTurma = Turma.idTurma
      JOIN Cursos ON Turma.idCurso = Cursos.idCurso
      JOIN Instrutores ON Turma.idInstrutor = Instrutores.idInstrutor
      JOIN Turno ON Turma.idTurno = Turno.idTurno
      ORDER BY Aulas.data, Aulas.horario
    ''');

    return aulas.map((aula) {
      final data = DateTime.parse(aula['data'] as String);
      aula['data_formatada'] = formatarParaBrasil(data);
      return aula;
    }).toList();
  }

   Future<int> insertAula(Map<String, dynamic> aula) async {
    final db = await database;

    if (aula['data'] is String && (aula['data'] as String).contains('/')) {
      final data = parseDataBrasileira(aula['data'] as String);
      if (data != null) {
        aula['data'] = formatarParaBanco(data);
      }
    }

    // Garante que o campo horas tenha um valor padrão se não foi fornecido
    aula['horas'] = aula['horas'] ?? 1;

    return await db.insert('Aulas', aula);
  }


  Future<int> updateAula(Map<String, dynamic> aula) async {
    final db = await database;

    if (aula['data'] is String && (aula['data'] as String).contains('/')) {
      final data = parseDataBrasileira(aula['data'] as String);
      if (data != null) {
        aula['data'] = formatarParaBanco(data);
      }
    }

    return await db.update(
      'Aulas',
      aula,
      where: 'idAula = ?',
      whereArgs: [aula['idAula']],
    );
  }

  Future<int> deleteAula(int idAula) async {
    final db = await database;
    return await db.delete(
      'Aulas',
      where: 'idAula = ?',
      whereArgs: [idAula],
    );
  }

  Future<List<Map<String, dynamic>>> getTurmas() async {
    final db = await database;
    return await db.query('Turma');
  }

  Future<List<Map<String, dynamic>>> getUnidadesCurriculares() async {
    final db = await database;
    return await db.query('Unidades_Curriculares');
  }

  Future<List<Map<String, dynamic>>> getCursos() async {
    final db = await database;
    return await db.query('Cursos');
  }

  Future<List<Map<String, dynamic>>> getInstrutores() async {
    final db = await database;
    return await db.query('Instrutores');
  }
}
