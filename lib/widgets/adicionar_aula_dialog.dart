// ignore_for_file: library_private_types_in_public_api

import 'package:cronograma/core/database_helper.dart';
import 'package:cronograma/data/models/aula_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdicionarAulaDialog extends StatefulWidget {
  final List<Map<String, dynamic>> turmas;
  final List<Map<String, dynamic>> ucs;
  final Map<int, int> cargaHorariaUc;
  final Set<DateTime> selectedDays;
  final Map<DateTime, List<Aula>> events;
  final Map<String, Map<String, dynamic>> periodoConfig;

  const AdicionarAulaDialog({
    super.key,
    required this.turmas,
    required this.ucs,
    required this.cargaHorariaUc,
    required this.selectedDays,
    required this.events,
    required this.periodoConfig,
  });

  @override
  _AdicionarAulaDialogState createState() => _AdicionarAulaDialogState();
}

class _AdicionarAulaDialogState extends State<AdicionarAulaDialog> {
  int? _selectedTurmaId;
  int? _selectedUcId;
  String _periodo = 'Matutino';
  int _horasAula = 1;
  List<Map<String, dynamic>> _ucsFiltradas = [];

  @override
  Widget build(BuildContext context) {
    final maxHoras = widget.periodoConfig[_periodo]!['maxHoras'] as int;
    final theme = Theme.of(context);

    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dropdown de Turma
            DropdownButtonFormField<int>(
              value: _selectedTurmaId,
              decoration: _buildInputDecoration('Turma', Icons.group),
              items: widget.turmas.map((turma) {
                return DropdownMenuItem<int>(
                  value: turma['idTurma'] as int,
                  child:
                      _buildDropdownItem(turma['turma'] as String, Icons.group),
                );
              }).toList(),
              onChanged: (value) async {
                if (value == null) return;
                final db = await DatabaseHelper.instance.database;
                final turma = (await db.query('Turma',
                        where: 'idTurma = ?', whereArgs: [value]))
                    .first;

                if (mounted) {
                  setState(() {
                    _selectedTurmaId = value;
                    _selectedUcId = null;
                    _ucsFiltradas = widget.ucs
                        .where((uc) => uc['idCurso'] == turma['idCurso'])
                        .toList();
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            // Dropdown de Unidade Curricular
            DropdownButtonFormField<int>(
              value: _selectedUcId,
              decoration:
                  _buildInputDecoration('Unidade Curricular', Icons.school),
              items: _ucsFiltradas.map((uc) {
                final cargaHoraria =
                    widget.cargaHorariaUc[uc['idUc'] as int] ?? 0;
                final podeAgendar = cargaHoraria >= _horasAula;
                final jaAgendada = widget.selectedDays.any((day) {
                  return widget.events[DateTime(day.year, day.month, day.day)]
                          ?.any((aula) => aula.idUc == uc['idUc']) ??
                      false;
                });

                return DropdownMenuItem<int>(
                  value: uc['idUc'] as int,
                  enabled: podeAgendar && !jaAgendada,
                  child: _buildUcItem(uc, cargaHoraria, jaAgendada),
                );
              }).toList(),
              onChanged: (value) {
                if (mounted) {
                  setState(() => _selectedUcId = value);
                }
              },
            ),

            const SizedBox(height: 20),

            // Dropdown de Período
            DropdownButtonFormField<String>(
              value: _periodo,
              decoration: _buildInputDecoration('Período', Icons.schedule),
              items: widget.periodoConfig.keys.map((periodo) {
                final bool podeAgendar;
                if (_selectedUcId == null) {
                  podeAgendar = true;
                } else {
                  final cargaHoraria =
                      widget.cargaHorariaUc[_selectedUcId] ?? 0;
                  podeAgendar = cargaHoraria >= _horasAula;
                }

                return DropdownMenuItem<String>(
                  value: periodo,
                  enabled: podeAgendar,
                  child: _buildDropdownItem(
                    periodo,
                    widget.periodoConfig[periodo]!['icon'] as IconData,
                  ),
                );
              }).toList(),
              onChanged: (String? novoPeriodo) {
                if (novoPeriodo == null || !mounted) return;

                final config = widget.periodoConfig[novoPeriodo];
                if (config == null) return;

                final maxHoras = config['maxHoras'] is int
                    ? config['maxHoras'] as int
                    : 1; // Valor padrão seguro

                if (_horasAula > maxHoras) {
                  setState(() {
                    _periodo = novoPeriodo;
                    _horasAula = maxHoras;
                  });
                } else {
                  setState(() => _periodo = novoPeriodo);
                }
              },
            ),

            const SizedBox(height: 20),

            // Seletor de horas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Horas por aula:', style: theme.textTheme.bodyLarge),
                  Slider(
                    value: _horasAula.toDouble(),
                    min: 1,
                    max: maxHoras.toDouble(),
                    divisions: maxHoras - 1,
                    label: '$_horasAula hora${_horasAula > 1 ? 's' : ''}',
                    onChanged: (value) {
                      if (mounted) {
                        setState(() => _horasAula = value.toInt());
                      }
                    },
                  ),
                ],
              ),
            ),

            if (widget.selectedDays.length > 1) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dias selecionados (${widget.selectedDays.length}):',
                        style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: widget.selectedDays.map((day) {
                        return Chip(
                          label: Text(DateFormat('dd/MM').format(day)),
                          backgroundColor: theme.colorScheme.primaryContainer,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_selectedUcId != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Informações da UC',
                            style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Carga horária restante:',
                        '${widget.cargaHorariaUc[_selectedUcId] ?? 0} horas'),
                    _buildInfoRow(
                        'Horas por aula:', '$_horasAula (máx. $maxHoras)'),
                    _buildInfoRow('Total de horas:',
                        '${_horasAula * widget.selectedDays.length}',
                        isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _podeSalvar() ? _salvar : null,
                  child: const Text('SALVAR'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildDropdownItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildUcItem(
      Map<String, dynamic> uc, int cargaHoraria, bool jaAgendada) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(uc['nome_uc'] as String,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('Carga restante: $cargaHoraria horas',
            style: TextStyle(
                color: cargaHoraria < _horasAula ? Colors.red : null)),
        if (jaAgendada)
          const Text('Já possui aula agendada',
              style: TextStyle(color: Colors.orange)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : null)),
        ],
      ),
    );
  }

  bool _podeSalvar() {
    // 1. Verificação básica de campos obrigatórios
    if (_selectedTurmaId == null || _selectedUcId == null) {
      return false;
    }

    // 2. Cálculo da carga horária
    final cargaDisponivel = widget.cargaHorariaUc[_selectedUcId] ?? 0;
    final cargaNecessaria = _horasAula * widget.selectedDays.length;

    // 3. Verificação de conflitos de agendamento
    bool temConflito = false;
    for (final day in widget.selectedDays) {
      final diaNormalizado = DateTime(day.year, day.month, day.day);
      final aulasNoDia = widget.events[diaNormalizado] ?? [];
      if (aulasNoDia.any((aula) => aula.idUc == _selectedUcId)) {
        temConflito = true;
        break;
      }
    }

    // 4. Retorno final com condições explícitas
    final bool temCargaSuficiente = cargaDisponivel >= cargaNecessaria;
    final bool semConflitos = !temConflito;

    return temCargaSuficiente && semConflitos;
  }

  void _salvar() {
    if (_selectedUcId == null || _selectedTurmaId == null || !mounted) return;

    Navigator.of(context).pop({
      'idTurma': _selectedTurmaId,
      'idUc': _selectedUcId,
      'periodo': _periodo,
      'horas': _horasAula,
      'horario': widget.periodoConfig[_periodo]!['horario'],
      'dias': widget.selectedDays,
    });
  }
}
