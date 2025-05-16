// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cronograma/core/database_helper.dart';

class AgendarAulasPage extends StatefulWidget {
  final Set<DateTime> selectedDays;
  final Map<String, Map<String, dynamic>> periodoConfig;

  const AgendarAulasPage({
    super.key,
    required this.selectedDays,
    required this.periodoConfig,
  });

  @override
  State<AgendarAulasPage> createState() => _AgendarAulasPageState();
}

class _AgendarAulasPageState extends State<AgendarAulasPage> {
  int? _selectedTurmaId;
  int? _selectedUcId;
  String _periodo = 'Matutino';
  int _horasAula = 1;
  List<Map<String, dynamic>> _turmas = [];
  List<Map<String, dynamic>> _ucs = [];
  List<Map<String, dynamic>> _ucsFiltradas = [];
  final Map<int, int> _cargaHorariaUc = {};
  bool _isLoading = false;
  int get _cargaHorariaRestante {
    if (_selectedUcId == null) return 0;

    final cargaAtual = _cargaHorariaUc[_selectedUcId] ?? 0;
    final horasAgendando = _horasAula * widget.selectedDays.length;

    return cargaAtual - horasAgendando;
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final turmas = await db.query('Turma');
      final ucs = await db.query('Unidades_Curriculares');

      final cargaHorariaMap = <int, int>{};
      for (var uc in ucs) {
        cargaHorariaMap[uc['idUc'] as int] = (uc['cargahoraria'] ?? 0) as int;
      }

      if (mounted) {
        setState(() {
          _turmas = turmas;
          _ucs = ucs;
          _ucsFiltradas = [];
          _cargaHorariaUc.addAll(cargaHorariaMap);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxHoras = widget.periodoConfig[_periodo]!['maxHoras'] as int;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Aulas'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _podeSalvar() && !_isLoading ? _salvarAulas : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Card de Dias Selecionados
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dias Selecionados',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: widget.selectedDays.map((day) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Chip(
                                  label: Text(DateFormat('EEEE, dd/MM', 'pt_BR')
                                      .format(day)),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () {
                                    setState(() {
                                      widget.selectedDays.remove(day);
                                    });
                                  },
                                  backgroundColor: colorScheme.primaryContainer,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total de horas a agendar: ${_horasAula * widget.selectedDays.length}',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Card de Configuração das Aulas
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          'Configuração das Aulas',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Dropdown de Turma
                        DropdownButtonFormField<int>(
                          value: _selectedTurmaId,
                          decoration: InputDecoration(
                            labelText: 'Turma',
                            prefixIcon:
                                Icon(Icons.group, color: colorScheme.primary),
                            border: const OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: colorScheme.primary),
                            ),
                          ),
                          items: _turmas.map((turma) {
                            return DropdownMenuItem<int>(
                              value: turma['idTurma'] as int,
                              child: Text(turma['turma'] as String),
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
                                _ucsFiltradas = _ucs
                                    .where((uc) =>
                                        uc['idCurso'] == turma['idCurso'])
                                    .toList();
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // Dropdown de Unidade Curricular
                        if (_selectedTurmaId != null) ...[
                          DropdownButtonFormField<int>(
                            isExpanded: true,
                            value: _selectedUcId,
                            decoration: InputDecoration(
                              labelText: 'Unidade Curricular',
                              prefixIcon: Icon(Icons.school,
                                  color: colorScheme.primary),
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: colorScheme.primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                            ),

                            // <<< aqui: controla o que aparece no campo quando um item está selecionado
                            selectedItemBuilder: (_) {
                              return _ucsFiltradas.map((uc) {
                                return Text(
                                  uc['nome_uc'] as String,
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                  style: const TextStyle(fontSize: 14),
                                );
                              }).toList();
                            },

                            items: _ucsFiltradas.map((uc) {
                              final cargaHoraria =
                                  _cargaHorariaUc[uc['idUc'] as int] ?? 0;
                              return DropdownMenuItem<int>(
                                value: uc['idUc'] as int,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // aqui continua mostrando nome + horas
                                    Text(
                                      uc['nome_uc'] as String,
                                      softWrap: true,
                                      maxLines: 2,
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$cargaHoraria horas restantes',
                                      style: TextStyle(
                                        color: cargaHoraria < _horasAula
                                            ? Colors.red
                                            : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),

                            onChanged: (value) {
                              if (mounted)
                                setState(() => _selectedUcId = value);
                            },
                            validator: (value) => value == null
                                ? 'Selecione uma unidade curricular'
                                : null,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Dropdown de Período
                        if (_selectedUcId != null) ...[
                          DropdownButtonFormField<String>(
                            value: _periodo,
                            decoration: InputDecoration(
                              labelText: 'Período',
                              prefixIcon: Icon(Icons.schedule,
                                  color: colorScheme.primary),
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: colorScheme.primary),
                              ),
                            ),
                            items: widget.periodoConfig.keys.map((periodo) {
                              return DropdownMenuItem<String>(
                                value: periodo,
                                child: Row(
                                  children: [
                                    Icon(widget.periodoConfig[periodo]!['icon']
                                        as IconData),
                                    const SizedBox(width: 12),
                                    Text(periodo),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? novoPeriodo) {
                              if (novoPeriodo == null || !mounted) return;

                              final config = widget.periodoConfig[novoPeriodo];
                              if (config == null) return;

                              final maxHoras = config['maxHoras'] is int
                                  ? config['maxHoras'] as int
                                  : 1;

                              setState(() {
                                _periodo = novoPeriodo;
                                if (_horasAula > maxHoras) {
                                  _horasAula = maxHoras;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 20),

                          // Seletor de horas
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Horas por aula: $_horasAula',
                                style: theme.textTheme.bodyLarge,
                              ),
                              Slider(
                                value: _horasAula.toDouble(),
                                min: 1,
                                max: maxHoras.toDouble(),
                                divisions: maxHoras > 1
                                    ? maxHoras - 1
                                    : 1, // Prevenir divisões zero
                                label:
                                    '$_horasAula hora${_horasAula > 1 ? 's' : ''}',
                                onChanged: (value) {
                                  if (mounted) {
                                    setState(() => _horasAula = value.toInt());
                                  }
                                },
                                activeColor: colorScheme.primary,
                                inactiveColor:
                                    colorScheme.primary.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Resumo e Botão de Salvar
                if (_selectedUcId != null) ...[
                  const SizedBox(height: 24),
                  // No Card do resumo, altere para:
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.9,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading:
                                  Icon(Icons.info, color: colorScheme.primary),
                              title: Text(
                                'Resumo do Agendamento',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            const Divider(),
                            _buildInfoRow('Período:', _periodo, theme),
                            _buildInfoRow(
                                'Horas por aula:', '$_horasAula', theme),
                            _buildInfoRow('Total de aulas:',
                                '${widget.selectedDays.length}', theme),
                            _buildInfoRow(
                                'Total de horas:',
                                '${_horasAula * widget.selectedDays.length}',
                                theme,
                                isBold: true),
                            _buildInfoRow('Carga horária restante:',
                                '$_cargaHorariaRestante horas', theme,
                                isAlert: _cargaHorariaRestante < 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _podeSalvar() && !_isLoading ? _salvarAulas : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.save, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Salvar Agendamento',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // No método _buildInfoRow, altere para:
  Widget _buildInfoRow(String label, String value, ThemeData theme,
      {bool isBold = false, bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Adicionado
        children: [
          SizedBox(
            width: 150, // Largura fixa para labels
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            // Adicionado Expanded
            child: Text(
              value,
              maxLines: 2, // Permite até 2 linhas
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isAlert ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _podeSalvar() {
    return _selectedTurmaId != null &&
        _selectedUcId != null &&
        widget.selectedDays.isNotEmpty;
  }

  Future<void> _salvarAulas() async {
    if (!_podeSalvar()) return;

    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final batch = db.batch();

      final cargaTotalNecessaria = _horasAula * widget.selectedDays.length;
      if ((_cargaHorariaUc[_selectedUcId] ?? 0) < cargaTotalNecessaria) {
        throw Exception('Carga horária insuficiente para esta UC');
      }

      for (final dia in widget.selectedDays) {
        batch.insert('Aulas', {
          'idUc': _selectedUcId,
          'idTurma': _selectedTurmaId,
          'data': DateFormat('yyyy-MM-dd').format(dia),
          'horario': widget.periodoConfig[_periodo]!['horario'],
          'status': 'Agendada',
          'horas': _horasAula,
        });
      }

      await batch.commit();

      // Atualiza carga horária
      final novaCarga =
          (_cargaHorariaUc[_selectedUcId] ?? 0) - cargaTotalNecessaria;
      await db.update(
        'Unidades_Curriculares',
        {'cargahoraria': novaCarga},
        where: 'idUc = ?',
        whereArgs: [_selectedUcId],
      );

      if (mounted) {
        Navigator.pop(context, true); // Retorna indicando sucesso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao agendar aulas: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}
