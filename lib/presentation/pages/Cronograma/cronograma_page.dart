// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, avoid_print

import 'package:cronograma/data/models/aula_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cronograma/core/database_helper.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cronograma/presentation/pages/Cronograma/agendar_aulas_page.dart';

class CronogramaPage extends StatefulWidget {
  const CronogramaPage({super.key});

  @override
  _CronogramaPageState createState() => _CronogramaPageState();
}

class _CronogramaPageState extends State<CronogramaPage> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final Set<DateTime> _selectedDays = {};
  // ignore: unused_field
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final Map<DateTime, List<Aula>> _events = {};
  final Map<DateTime, List<Aula>> _filteredEvents = {};
  final Map<DateTime, String> _feriados = {};
  bool _isLoading = true;
  final Map<int, int> _cargaHorariaUc = {};
  List<Map<String, dynamic>> _turmas = [];
  int? _selectedTurmaId;

  final Map<String, Map<String, dynamic>> _periodoConfig = {
    'Matutino': {
      'maxHoras': 4,
      'horario': '08:00-12:00',
      'icon': Icons.wb_sunny_outlined,
    },
    'Vespertino': {
      'maxHoras': 4,
      'horario': '14:00-18:00',
      'icon': Icons.brightness_5,
    },
    'Noturno': {
      'maxHoras': 3,
      'horario': '19:00-22:00',
      'icon': Icons.nights_stay_outlined,
    },
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;
    _carregarFeriadosBrasileiros(now.year);
    _carregarTurmas().then((_) => _carregarAulas());
    _carregarCargaHorariaUc();
  }

  Future<void> _carregarTurmas() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final turmas = await db.query('Turma');
      setState(() {
        _turmas = turmas;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar turmas: $e')),
        );
      }
    }
  }

  Future<void> _carregarFeriadosBrasileiros(int ano) async {
    _feriados[DateTime(ano, 1, 1)] = '🎉 Ano Novo';
    _feriados[DateTime(ano, 4, 21)] = '🎖 Tiradentes';
    _feriados[DateTime(ano, 5, 1)] = '👷 Dia do Trabalho';
    _feriados[DateTime(ano, 9, 7)] = '🇧🇷 Independência do Brasil';
    _feriados[DateTime(ano, 10, 12)] = '🙏 Nossa Senhora Aparecida';
    _feriados[DateTime(ano, 11, 2)] = '🕯 Finados';
    _feriados[DateTime(ano, 11, 15)] = '🏛 Proclamação da República';
    _feriados[DateTime(ano, 12, 25)] = '🎄 Natal';

    final pascoa = _calcularPascoa(ano);
    _feriados[pascoa] = '🐣 Páscoa';
    _feriados[pascoa.subtract(const Duration(days: 2))] = '✝ Sexta-Feira Santa';
    _feriados[pascoa.subtract(const Duration(days: 47))] = '🎭 Carnaval';
    _feriados[pascoa.add(const Duration(days: 60))] = '🍞 Corpus Christi';
  }

  DateTime _calcularPascoa(int ano) {
    final a = ano % 19;
    final b = ano ~/ 100;
    final c = ano % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final mes = (h + l - 7 * m + 114) ~/ 31;
    final dia = (h + l - 7 * m + 114) % 31 + 1;

    return DateTime(ano, mes, dia);
  }

  Future<void> _carregarAulas() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final aulas = await db.query('Aulas');

      final Map<DateTime, List<Aula>> events = {};
      for (var aula in aulas) {
        final date = DateTime.parse(aula['data'] as String);
        final normalizedDate = DateTime(date.year, date.month, date.day);

        final aulaObj = Aula(
          idAula: aula['idAula'] as int,
          idUc: aula['idUc'] as int,
          idTurma: aula['idTurma'] as int,
          data: date,
          horario: aula['horario'] as String,
          status: aula['status'] as String,
          horas: aula['horas'] as int? ?? 1,
        );

        events.putIfAbsent(normalizedDate, () => []).add(aulaObj);
      }

      if (mounted) {
        setState(() {
          _events.clear();
          _events.addAll(events);
          _aplicarFiltroTurma();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar aulas: $e')),
        );
      }
    }
  }

  void _aplicarFiltroTurma() {
    _filteredEvents.clear();

    if (_selectedTurmaId == null) {
      _filteredEvents.addAll(_events);
      return;
    }

    for (var entry in _events.entries) {
      final filteredAulas = entry.value
          .where((aula) => aula.idTurma == _selectedTurmaId)
          .toList();

      if (filteredAulas.isNotEmpty) {
        _filteredEvents[entry.key] = filteredAulas;
      }
    }
  }

  Future<void> _carregarCargaHorariaUc() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final ucs = await db.query('Unidades_Curriculares');

      if (mounted) {
        setState(() {
          _cargaHorariaUc.clear();
          for (var uc in ucs) {
            _cargaHorariaUc[uc['idUc'] as int] =
                (uc['cargahoraria'] ?? 0) as int;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar carga horária: $e')),
        );
      }
    }
  }

  bool _isFeriado(DateTime day) {
    return _feriados.containsKey(DateTime(day.year, day.month, day.day));
  }

  bool _isDiaUtil(DateTime day) {
    if (day.weekday == 6 || day.weekday == 7) return false;
    if (_isFeriado(day)) return false;
    return true;
  }

  Future<void> _adicionarAula() async {
    try {
      if ((_selectedDays.isEmpty && _selectedDay == null) || !mounted) return;

      final diasParaAgendar =
          _selectedDays.isNotEmpty ? _selectedDays : {_selectedDay!};

      final diasInvalidos =
          diasParaAgendar.where((day) => !_isDiaUtil(day)).toList();

      if (diasInvalidos.isNotEmpty) {
        final formatados =
            diasInvalidos.map((d) => DateFormat('dd/MM').format(d)).join(', ');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Não é possível agendar em finais de semana ou feriados: $formatados')),
          );
        }
        return;
      }

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => AgendarAulasPage(
            selectedDays: diasParaAgendar,
            periodoConfig: _periodoConfig,
          ),
        ),
      );

      if (result == true) {
        await _carregarAulas();
        await _carregarCargaHorariaUc();

        if (mounted) {
          setState(() {
            _selectedDays.clear();
            _selectedDay = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aulas agendadas com sucesso!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar aula: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _imprimirCronogramaWindows() async {
    final pdf = pw.Document();

    // Carrega os dados da turma selecionada
    final turmaInfo = _selectedTurmaId != null
        ? _turmas.firstWhere((t) => t['idTurma'] == _selectedTurmaId)
        : null;

    String nomeCurso = 'Não especificado';
    if (turmaInfo != null && turmaInfo['idCurso'] != null) {
      try {
        final db = await DatabaseHelper.instance.database;
        final curso = await db.query(
          'Cursos',
          where: 'idCurso = ?',
          whereArgs: [turmaInfo['idCurso']],
          limit: 1,
        );
        if (curso.isNotEmpty) {
          nomeCurso = curso.first['nome_curso'] as String;
        }
      } catch (e) {
        print('Erro ao buscar curso: $e');
      }
    }

    // Carrega todos os dados necessários antes de construir o PDF
    final List<Future> futures = [];
    final Map<DateTime, List<Map<String, dynamic>>> aulasComDetalhes = {};

    for (var entry in _filteredEvents.entries) {
      for (var aula in entry.value) {
        futures.add(_getAulaDetails(aula.idAula!).then((detalhes) {
          aulasComDetalhes.putIfAbsent(entry.key, () => []).add(detalhes);
        }));
      }
    }

    await Future.wait(futures);

    // Agrupa aulas por UC
    final Map<String, List<Map<String, dynamic>>> aulasPorUc = {};
    for (var entry in aulasComDetalhes.entries) {
      for (var aula in entry.value) {
        final uc = aula['nome_uc'] as String;
        aulasPorUc.putIfAbsent(uc, () => []).add(aula);
      }
    }

    // Determina os dias da semana com aulas
    final diasComAulas = <int>{};
    for (var data in aulasComDetalhes.keys) {
      diasComAulas.add(data.weekday);
    }

    // Formata o período baseado nos dias com aula
    final periodoFormatado = _formatarPeriodo(diasComAulas.toList());

    // Cores básicas para cada UC
    final ucColors = <String, PdfColor>{};
    final basicColors = [
      PdfColors.green,
      PdfColors.orange,
      PdfColors.purple,
      PdfColors.yellow,
      PdfColors.teal,
      PdfColors.pink,
    ];

    int colorIndex = 0;
    for (var uc in aulasPorUc.keys) {
      ucColors[uc] = basicColors[colorIndex % basicColors.length];
      colorIndex++;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return [
            // Cabeçalho
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('SENAC CATALÃO',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Text('CURSO: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(nomeCurso),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text('TURMA: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(turmaInfo?['turma'] ?? 'Todas as Turmas'),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text('PERÍODO: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(periodoFormatado),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text('HORÁRIO: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(turmaInfo?['horario'] ?? ''),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text('CRONOGRAMA DE AULAS - ${DateTime.now().year}',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 20),

                // LEGENDA
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendaItem(
                        'F', 'Feriado', PdfColors.red100, PdfColors.red),
                    _buildLegendaItem('FDS', 'Fim de semana', PdfColors.red100,
                        PdfColors.red),
                    _buildLegendaItem('Xh', 'Aula (horas)', PdfColors.blue100,
                        PdfColors.blue900),
                    _buildLegendaItem(
                        '', 'Dia sem aula', PdfColors.grey200, PdfColors.black),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],
            ),

            // Tabela de meses
            for (var mes in _getMesesComAulas(aulasComDetalhes))
              _buildTabelaMes(mes, aulasPorUc, ucColors),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      usePrinterSettings: true,
    );
  }

  pw.Widget _buildLegendaItem(
      String simbolo, String descricao, PdfColor corFundo, PdfColor corTexto) {
    return pw.Row(
      children: [
        pw.Container(
          width: 20,
          height: 20,
          decoration: pw.BoxDecoration(
            color: corFundo,
            border: pw.Border.all(),
          ),
          child: pw.Center(
            child: pw.Text(
              simbolo,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: corTexto,
              ),
            ),
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Text(
          descricao,
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(width: 10),
      ],
    );
  }

  String _formatarPeriodo(List<int> diasDaSemana) {
    if (diasDaSemana.isEmpty) return 'Nenhuma aula marcada';

    diasDaSemana.sort();

    // Mapeia números dos dias para abreviações
    final diasMap = {
      1: 'Seg',
      2: 'Ter',
      3: 'Qua',
      4: 'Qui',
      5: 'Sex',
      6: 'Sáb',
      7: 'Dom',
    };

    // Se tiver todos os dias úteis (segunda a sexta)
    if (diasDaSemana.contains(1) &&
        diasDaSemana.contains(2) &&
        diasDaSemana.contains(3) &&
        diasDaSemana.contains(4) &&
        diasDaSemana.contains(5)) {
      return 'Segunda a Sexta';
    }

    // Se tiver todos os dias da semana
    if (diasDaSemana.contains(1) &&
        diasDaSemana.contains(2) &&
        diasDaSemana.contains(3) &&
        diasDaSemana.contains(4) &&
        diasDaSemana.contains(5) &&
        diasDaSemana.contains(6) &&
        diasDaSemana.contains(7)) {
      return 'Todos os dias';
    }

    // Caso contrário, lista os dias específicos
    return diasDaSemana.map((dia) => diasMap[dia]).join(', ');
  }

  List<DateTime> _getMesesComAulas(
      Map<DateTime, List<Map<String, dynamic>>> aulasComDetalhes) {
    final Set<DateTime> meses = {};
    for (var data in aulasComDetalhes.keys) {
      meses.add(DateTime(data.year, data.month, 1));
    }
    final mesesList = meses.toList();
    mesesList.sort((a, b) => a.compareTo(b));
    return mesesList;
  }

  pw.Widget _buildTabelaMes(
      DateTime mes,
      Map<String, List<Map<String, dynamic>>> aulasPorUc,
      Map<String, PdfColor> ucColors) {
    final nomeMes = DateFormat('MMMM', 'pt_BR').format(mes);
    final diasNoMes = DateTime(mes.year, mes.month + 1, 0).day;
    final dias = <DateTime>[];
    for (var i = 1; i <= diasNoMes; i++) {
      dias.add(DateTime(mes.year, mes.month, i));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(nomeMes,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        // Tabela principal
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FixedColumnWidth(150),
            ...{
              for (var i in List.generate(diasNoMes, (i) => i + 1))
                i: const pw.FixedColumnWidth(25)
            },
          },
          children: [
            // Linha com nomes completos dos dias da semana
            pw.TableRow(
              children: [
                pw.Container(),
                for (var dia in dias)
                  pw.Container(
                    color: _isFeriado(dia) ? PdfColors.red100 : null,
                    child: pw.Center(
                      child: pw.Text(
                        DateFormat('E', 'pt_BR').format(dia).substring(0, 3),
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: _isFeriado(dia) ? PdfColors.red : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Linha com números dos dias
            pw.TableRow(
              children: [
                pw.Container(),
                for (var dia in dias)
                  pw.Container(
                    color: _isFeriado(dia) ? PdfColors.red100 : null,
                    child: pw.Center(
                      child: pw.Text(
                        '${dia.day}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: _isFeriado(dia) ? PdfColors.red : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Linhas para cada UC
            for (var uc in aulasPorUc.keys)
              pw.TableRow(
                children: [
                  pw.Container(
                    color: ucColors[uc],
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        uc,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                  ),
                  for (var dia in dias)
                    _getCelulaDia(uc, dia, aulasPorUc, ucColors),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _getCelulaDia(
      String uc,
      DateTime dia,
      Map<String, List<Map<String, dynamic>>> aulasPorUc,
      Map<String, PdfColor> ucColors) {
    // Verifica se é fim de semana (sábado=6, domingo=7) ou feriado
    final isFimDeSemanaOuFeriado =
        dia.weekday == 6 || dia.weekday == 7 || _isFeriado(dia);

    if (isFimDeSemanaOuFeriado) {
      return pw.Container(
        height: 20,
        decoration: pw.BoxDecoration(
          color: PdfColors.red100,
          border: pw.Border.all(),
        ),
        child: pw.Center(
          child: pw.Text(
            dia.weekday == 6 || dia.weekday == 7
                ? 'FDS'
                : 'F', // FDS para fim de semana, F para feriado
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red,
            ),
          ),
        ),
      );
    }

    final aulasDesteDia = aulasPorUc[uc]?.where((aula) {
      final aulaDate = DateTime.parse(aula['data']);
      return aulaDate.year == dia.year &&
          aulaDate.month == dia.month &&
          aulaDate.day == dia.day;
    }).toList();

    if (aulasDesteDia == null || aulasDesteDia.isEmpty) {
      return pw.Container(
        height: 20,
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          border: pw.Border.all(),
        ),
        child: pw.SizedBox(),
      );
    }

    // Soma as horas de todas as aulas deste dia para esta UC
    final totalHoras = aulasDesteDia.fold<int>(0, (sum, aula) {
      return sum + (aula['horas'] as int? ?? 0);
    });

    return pw.Container(
      height: 20,
      decoration: pw.BoxDecoration(
        color: PdfColors.blue100,
        border: pw.Border.all(),
      ),
      child: pw.Center(
        child: pw.Text(
          '${totalHoras}h',
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
      ),
    );
  }

  Future<void> _removerAula(
      int idAula, int idUc, String horario, int horas) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final aula = await db.query(
        'Aulas',
        where: 'idAula = ?',
        whereArgs: [idAula],
        limit: 1,
      );

      if (aula.isEmpty) {
        throw Exception('Aula não encontrada');
      }

      await db.delete('Aulas', where: 'idAula = ?', whereArgs: [idAula]);

      final horasParaRestaurar =
          aula.first['horas'] as int? ?? (horario == '19:00-22:00' ? 3 : 4);

      setState(() {
        _cargaHorariaUc[idUc] =
            (_cargaHorariaUc[idUc] ?? 0) + horasParaRestaurar;
      });

      await db.update(
        'Unidades_Curriculares',
        {'cargahoraria': _cargaHorariaUc[idUc]},
        where: 'idUc = ?',
        whereArgs: [idUc],
      );

      if (mounted) {
        await _carregarAulas();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Aula removida com sucesso! ($horasParaRestaurar horas restauradas)'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover aula: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  List<Aula> _getEventsForDay(DateTime day) {
    if (_selectedTurmaId == null) {
      return _events[DateTime(day.year, day.month, day.day)] ?? [];
    } else {
      return _filteredEvents[DateTime(day.year, day.month, day.day)] ?? [];
    }
  }

  String? _getFeriadoForDay(DateTime day) {
    return _feriados[DateTime(day.year, day.month, day.day)];
  }

  Widget _buildEventList() {
    if (_selectedDay == null && _selectedDays.isEmpty) return const SizedBox();

    if (_selectedDay != null && _selectedDays.isEmpty) {
      final events = _getEventsForDay(_selectedDay!);
      final feriado = _getFeriadoForDay(_selectedDay!);

      return _buildDayEvents(_selectedDay!, events, feriado);
    }

    return ListView(
      children: _selectedDays.map((day) {
        final events = _getEventsForDay(day);
        final feriado = _getFeriadoForDay(day);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                DateFormat('EEEE, dd/MM', 'pt_BR').format(day),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            _buildDayEvents(day, events, feriado),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDayEvents(DateTime day, List<Aula> events, String? feriado) {
    return Column(
      children: [
        if (feriado != null)
          Card(
            color: Colors.amber[100],
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.celebration, color: Colors.orange),
              title: Text(feriado),
            ),
          ),
        if (events.isEmpty && feriado == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Nenhuma aula agendada'),
          ),
        ...events.map((aula) => _buildAulaCard(aula)),
      ],
    );
  }

  Widget _buildAulaCard(Aula aula) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 10,
          height: 40,
          color: _getColorByStatus(aula.status),
        ),
        title: FutureBuilder<Map<String, dynamic>>(
          future: _getAulaDetails(aula.idAula!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Carregando...');
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Text('Erro ao carregar dados');
            }
            final data = snapshot.data!;
            return Text('${data['nome_uc']} - ${data['turma']}');
          },
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _getAulaDetails(aula.idAula!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Carregando...');
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Erro ao carregar dados');
                }
                final data = snapshot.data!;
                return Text('Instrutor: ${data['nome_instrutor']}');
              },
            ),
            Text('Horário: ${aula.horario}'),
            Text('Status: ${aula.status}'),
            FutureBuilder<Map<String, dynamic>>(
              future: _getAulaDetails(aula.idAula!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Carregando...');
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Erro ao carregar dados');
                }
                final cargaRestante = _cargaHorariaUc[aula.idUc] ?? 0;
                return Text('Carga horária restante: $cargaRestante horas');
              },
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () =>
              _removerAula(aula.idAula!, aula.idUc, aula.horario, aula.horas),
        ),
      ),
    );
  }

  Color _getColorByStatus(String status) {
    switch (status) {
      case 'Realizada':
        return Colors.green;
      case 'Cancelada':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Future<Map<String, dynamic>> _getAulaDetails(int idAula) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('''
        SELECT Aulas.*, Unidades_Curriculares.nome_uc, Turma.turma, Instrutores.nome_instrutor
        FROM Aulas
        JOIN Unidades_Curriculares ON Aulas.idUc = Unidades_Curriculares.idUc
        JOIN Turma ON Aulas.idTurma = Turma.idTurma
        JOIN Instrutores ON Turma.idInstrutor = Instrutores.idInstrutor
        WHERE Aulas.idAula = ?
      ''', [idAula]);

      if (result.isEmpty) {
        return {
          'nome_uc': 'Não encontrado',
          'turma': 'Não encontrada',
          'nome_instrutor': 'Não encontrado',
          'horario': '',
          'status': '',
          'horas': 0
        };
      }

      return result.first;
    } catch (e) {
      return {
        'nome_uc': 'Erro: $e',
        'turma': 'Erro: $e',
        'nome_instrutor': 'Erro: $e',
        'horario': '',
        'status': '',
        'horas': 0
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronograma de Aulas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _imprimirCronogramaWindows,
          ),
          IconButton(
            icon: const Icon(Icons.event),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Feriados Nacionais'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _feriados.entries
                        .map((e) => ListTile(
                              leading: const Icon(Icons.celebration),
                              title: Text(e.value),
                              subtitle: Text(
                                DateFormat('EEEE, dd/MM/yyyy', 'pt_BR')
                                    .format(e.key),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarAula,
        tooltip: 'Agendar aulas',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _selectedTurmaId,
                    decoration: InputDecoration(
                      labelText: 'Filtrar por Turma',
                      prefixIcon:
                          Icon(Icons.filter_list, color: colorScheme.primary),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Todas as Turmas'),
                      ),
                      ..._turmas.map((turma) {
                        return DropdownMenuItem<int>(
                          value: turma['idTurma'] as int,
                          child: Text(turma['turma'] as String),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTurmaId = value;
                        _aplicarFiltroTurma();
                      });
                    },
                  ),
                ),
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return _selectedDays.contains(day) ||
                        isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;

                      final isShiftPressed = HardwareKeyboard
                          .instance.logicalKeysPressed
                          .any((key) =>
                              key == LogicalKeyboardKey.shiftLeft ||
                              key == LogicalKeyboardKey.shiftRight);
                      final isCtrlPressed = HardwareKeyboard
                          .instance.logicalKeysPressed
                          .any((key) =>
                              key == LogicalKeyboardKey.controlLeft ||
                              key == LogicalKeyboardKey.controlRight);

                      if (isShiftPressed || isCtrlPressed) {
                        if (_selectedDays.contains(selectedDay)) {
                          _selectedDays.remove(selectedDay);
                        } else {
                          _selectedDays.add(selectedDay);
                        }
                        _selectedDay = null;
                      } else {
                        _selectedDays.clear();
                        _selectedDay = selectedDay;
                      }
                    });
                  },
                  onFormatChanged: (format) =>
                      setState(() => _calendarFormat = format),
                  onPageChanged: (focusedDay) =>
                      setState(() => _focusedDay = focusedDay),
                  eventLoader: _getEventsForDay,
                  calendarStyle: CalendarStyle(
                    weekendTextStyle: const TextStyle(color: Colors.red),
                    holidayTextStyle: TextStyle(color: Colors.red[800]),
                    markerDecoration: BoxDecoration(
                      color: Colors.blue[400],
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    outsideDaysVisible: false,
                  ),
                  headerStyle: HeaderStyle(
                    titleTextFormatter: (date, locale) =>
                        DateFormat('MMMM yyyy', 'pt_BR')
                            .format(date)
                            .toUpperCase(),
                    formatButtonVisible: false,
                    leftChevronIcon: const Icon(Icons.chevron_left),
                    rightChevronIcon: const Icon(Icons.chevron_right),
                    formatButtonDecoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    formatButtonTextStyle: const TextStyle(color: Colors.white),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
                    weekendStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    dowBuilder: (context, day) {
                      final text = DateFormat.EEEE('pt_BR').format(day);
                      return Center(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: day.weekday == 6 || day.weekday == 7
                                ? Colors.red
                                : null,
                          ),
                        ),
                      );
                    },
                    defaultBuilder: (context, date, _) {
                      final isFeriado = _isFeriado(date);
                      final isWeekend = date.weekday == 6 || date.weekday == 7;
                      final isToday = isSameDay(date, DateTime.now());
                      final isSelected = _selectedDays.contains(date) ||
                          isSameDay(_selectedDay, date);

                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isToday
                              ? Colors.orange.withOpacity(0.3)
                              : isFeriado
                                  ? Colors.red[50]
                                  : isSelected
                                      ? Colors.blue[100]
                                      : null,
                          border: Border.all(
                            color: isToday
                                ? Colors.orange
                                : isFeriado
                                    ? Colors.red
                                    : isSelected
                                        ? Colors.blue
                                        : Colors.transparent,
                            width: isToday ? 2 : 1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isFeriado
                                  ? Colors.red[800]
                                  : isWeekend
                                      ? Colors.red
                                      : isSelected
                                          ? Colors.blue[900]
                                          : null,
                              fontWeight: isFeriado || isSelected
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedDays.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '${_selectedDays.length} dia(s) selecionado(s)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                Expanded(
                  child: _buildEventList(),
                ),
              ],
            ),
    );
  }
}
