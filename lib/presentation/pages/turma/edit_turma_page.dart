import 'package:cronograma/data/models/cursos_model.dart';
import 'package:cronograma/data/models/instrutores_model.dart';
import 'package:cronograma/data/models/turma_model.dart';
import 'package:cronograma/data/repositories/turma_repository.dart';
import 'package:cronograma/data/repositories/turno_repository.dart';
import 'package:cronograma/presentation/viewmodels/turma_viewmodels.dart';
import 'package:cronograma/presentation/viewmodels/turno_viewmodels.dart';
import 'package:flutter/material.dart';

class EditTurmaPage extends StatefulWidget {
  final Turma turma;
  final List<String> turnos;
  final List<Cursos> cursos;
  final List<Instrutores> instrutores;

  const EditTurmaPage({
    super.key,
    required this.turma,
    required this.turnos,
    required this.cursos,
    required this.instrutores,
  });

  @override
  State<EditTurmaPage> createState() => _EditTurmaPageState();
}

class _EditTurmaPageState extends State<EditTurmaPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _turmaController;
  late String _turnoSelecionado;
  late int? _cursoIdSelecionado;
  late int? _instrutorIdSelecionado;
  final TurmaViewModel _viewModel = TurmaViewModel(TurmaRepository());
  final TurnoViewModel _turnoViewModel = TurnoViewModel(TurnoRepository());
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _turmaController = TextEditingController(text: widget.turma.turma);
    
    // Inicialização segura do turno selecionado
    _turnoSelecionado = widget.turnos.isNotEmpty && widget.turma.idturno > 0 && widget.turma.idturno <= widget.turnos.length
        ? widget.turnos[widget.turma.idturno - 1]
        : widget.turnos.isNotEmpty ? widget.turnos.first : 'Matutino';

    // Inicialização segura do curso selecionado
    _cursoIdSelecionado = widget.cursos.any((c) => c.idCurso == widget.turma.idcurso)
        ? widget.turma.idcurso
        : widget.cursos.isNotEmpty ? widget.cursos.first.idCurso : null;

    // Inicialização segura do instrutor selecionado
    _instrutorIdSelecionado = widget.instrutores.any((i) => i.idInstrutor == widget.turma.idinstrutor)
        ? widget.turma.idinstrutor
        : widget.instrutores.isNotEmpty ? widget.instrutores.first.idInstrutor : null;
  }

  @override
  void dispose() {
    _turmaController.dispose();
    super.dispose();
  }

  Future<void> _updateTurma() async {
    if (!_formKey.currentState!.validate() || 
        _cursoIdSelecionado == null || 
        _instrutorIdSelecionado == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final turnoId = await _turnoViewModel.getTurnoIdByNome(_turnoSelecionado);

      final turmaAtualizada = Turma(
        idTurma: widget.turma.idTurma,
        turma: _turmaController.text,
        idcurso: _cursoIdSelecionado!,
        idturno: turnoId!,
        idinstrutor: _instrutorIdSelecionado!,
      );

      await _viewModel.updateTurma(turmaAtualizada);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Turma atualizada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Turma'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateTurma,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Editar Turma',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _turmaController,
                        decoration: InputDecoration(
                          labelText: 'Identificação da Turma',
                          prefixIcon: Icon(Icons.groups, color: colorScheme.primary),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira a identificação';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _turnoSelecionado,
                        items: widget.turnos.map((turno) {
                          return DropdownMenuItem<String>(
                            value: turno,
                            child: Text(turno),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() => _turnoSelecionado = value);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Turno',
                          prefixIcon: Icon(Icons.schedule, color: colorScheme.primary),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                        validator: (value) =>
                            value == null ? 'Selecione um turno' : null,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int>(
                        value: _cursoIdSelecionado,
                        items: widget.cursos.map((curso) {
                          return DropdownMenuItem<int>(
                            value: curso.idCurso,
                            child: Text(curso.nomeCurso),
                          );
                        }).toList(),
                        onChanged: (int? value) {
                          if (value != null) {
                            setState(() => _cursoIdSelecionado = value);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Curso',
                          prefixIcon: Icon(Icons.school, color: colorScheme.primary),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                        validator: (value) =>
                            value == null ? 'Selecione um curso' : null,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int>(
                        value: _instrutorIdSelecionado,
                        items: widget.instrutores.map((instrutor) {
                          return DropdownMenuItem<int>(
                            value: instrutor.idInstrutor,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(instrutor.nomeInstrutor),
                                const SizedBox(width: 8),
                                if (instrutor.especializacao != null)
                                  Text(
                                    '- ${instrutor.especializacao!}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (int? value) {
                          if (value != null) {
                            setState(() => _instrutorIdSelecionado = value);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Instrutor',
                          prefixIcon: Icon(Icons.person, color: colorScheme.primary),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                        validator: (value) =>
                            value == null ? 'Selecione um instrutor' : null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateTurma,
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
                                      'Salvar Alterações',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}