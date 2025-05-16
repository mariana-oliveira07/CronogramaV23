import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PDFGenerator {
  Future<void> generatePDF(
    BuildContext context,
    String nomeCurso,
    String turma,
    String periodo,
    String horario,
    Map<DateTime, List<Map<String, dynamic>>> aulasPorData,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final currentYear = now.year;

    // Cabeçalho padrão
    final header = pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('SENAC CATALÃO', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text('CURSO: $nomeCurso', style: const pw.TextStyle(fontSize: 12)),
          pw.Text('TURMA: $turma', style: const pw.TextStyle(fontSize: 12)),
          pw.Text('PERÍODO: $periodo', style: const pw.TextStyle(fontSize: 12)),
          pw.Text('HORÁRIO: $horario', style: const pw.TextStyle(fontSize: 12)),
          pw.Text('CRONOGRAMA DE AULAS - $currentYear', 
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );

    // Organiza as aulas por mês
    final Map<String, List<Map<String, dynamic>>> aulasPorMes = {};
    final dateFormat = DateFormat('MMMM yyyy', 'pt_BR');

    aulasPorData.forEach((date, aulas) {
      final mesAno = dateFormat.format(date);
      aulasPorMes.putIfAbsent(mesAno, () => []).addAll(aulas);
    });

    // Gera uma página para cada mês
    aulasPorMes.forEach((mesAno, aulas) {
      final firstDay = aulasPorData.keys.firstWhere(
        (d) => dateFormat.format(d) == mesAno,
        orElse: () => DateTime.now(),
      );
      final daysInMonth = DateUtils.getDaysInMonth(firstDay.year, firstDay.month);

      // Cria a tabela de dias do mês
      final List<pw.Widget> dayHeaders = [];
      final List<pw.Widget> dayNumbers = [];
      
      for (int day = 1; day <= daysInMonth; day++) {
        final weekday = DateTime(firstDay.year, firstDay.month, day).weekday;
        final dayName = _getShortWeekdayName(weekday);
        
        dayHeaders.add(pw.Container(
          width: 15,
          height: 15,
          alignment: pw.Alignment.center,
          child: pw.Text(dayName, style: const pw.TextStyle(fontSize: 8)),
        ));
        
        dayNumbers.add(pw.Container(
          width: 15,
          height: 15,
          alignment: pw.Alignment.center,
          child: pw.Text(day.toString(), style: const pw.TextStyle(fontSize: 8)),
        ));
      }

      // Cria as linhas das UCs
      final ucRows = <pw.TableRow>[];
      final ucs = <String, List<int>>{};
      
      for (var aula in aulas) {
        final ucNome = aula['nome_uc'] as String? ?? 'UC Desconhecida';
        final dia = DateTime.parse(aula['data'] as String).day;
        
        ucs.putIfAbsent(ucNome, () => []).add(dia);
      }

      for (var uc in ucs.entries) {
        final cells = <pw.Widget>[
          pw.Container(
            width: 200,
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(uc.key, style: const pw.TextStyle(fontSize: 8)),
          ),
        ];

        for (int day = 1; day <= daysInMonth; day++) {
          final hasClass = uc.value.contains(day);
          cells.add(pw.Container(
            width: 15,
            height: 15,
            alignment: pw.Alignment.center,
            decoration: hasClass ? pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black),
            ) : null,
            child: hasClass ? pw.Text('X', style: const pw.TextStyle(fontSize: 8)) : null,
          ));
        }

        ucRows.add(pw.TableRow(children: cells));
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                header,
                pw.Text(mesAno.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                
                // Dias da semana
                pw.Row(
                  children: [
                    pw.SizedBox(width: 200),
                    ...dayHeaders,
                  ],
                ),
                
                // Números dos dias
                pw.Row(
                  children: [
                    pw.SizedBox(width: 200),
                    ...dayNumbers,
                  ],
                ),
                
                pw.SizedBox(height: 10),
                
                // Tabela de UCs
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                  children: [
                    // Cabeçalho
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Unidades Curriculares', 
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ),
                        ...List.generate(daysInMonth, (index) => pw.Container(
                          width: 15,
                          height: 15,
                          alignment: pw.Alignment.center,
                        )),
                      ],
                    ),
                    // Linhas das UCs
                    ...ucRows,
                  ],
                ),
              ],
            );
          },
        ),
      );
    });

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  String _getShortWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return 'seg';
      case 2: return 'ter';
      case 3: return 'qua';
      case 4: return 'qui';
      case 5: return 'sex';
      case 6: return 'sáb';
      case 7: return 'dom';
      default: return '';
    }
  }
}